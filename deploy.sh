#!/usr/bin/env bash
# ============================================================
#  TecDive — deploy.sh
#  Syncs site files to S3 and invalidates CloudFront cache.
#  Run via Git Bash or WSL on Windows.
#
#  Usage:
#    ./deploy.sh                   — full deploy
#    ./deploy.sh --no-invalidate   — sync only, skip invalidation
#    ./deploy.sh --invalidate-only — invalidation only, no sync
# ============================================================
set -euo pipefail

# ── LOAD CONFIG ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/.deploy-config"

# Defaults (override in .deploy-config or environment)
BUCKET_NAME="${BUCKET_NAME:-tecdive-rs-static}"
CF_DISTRIBUTION_ID="${CF_DISTRIBUTION_ID:-}"   # REQUIRED — set in .deploy-config
AWS_PROFILE="${AWS_PROFILE:-default}"

# Load config file if it exists
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
fi

# Validate required values
if [[ -z "$CF_DISTRIBUTION_ID" ]]; then
  echo "[error] CF_DISTRIBUTION_ID is not set."
  echo "        Run ./aws-setup.sh first, or set CF_DISTRIBUTION_ID in .deploy-config"
  exit 1
fi

# ── PARSE FLAGS ───────────────────────────────────────────────
SKIP_SYNC=false
SKIP_INVALIDATION=false

for arg in "$@"; do
  case "$arg" in
    --no-invalidate)   SKIP_INVALIDATION=true ;;
    --invalidate-only) SKIP_SYNC=true ;;
  esac
done

# ── HELPERS ──────────────────────────────────────────────────
log()  { echo -e "\n\033[1;34m[deploy]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[ok]\033[0m $*"; }
info() { echo -e "\033[0;37m        $*\033[0m"; }

S3_URL="s3://${BUCKET_NAME}"

# ── SYNC ─────────────────────────────────────────────────────
if [[ "$SKIP_SYNC" == false ]]; then

  # 1. HTML — short cache (5 minutes)
  #    --delete removes files from S3 that no longer exist locally
  log "Syncing HTML files (max-age=300)..."
  aws s3 sync "$SCRIPT_DIR" "$S3_URL/" \
    --exclude "*" \
    --include "*.html" \
    --cache-control "public, max-age=300, stale-while-revalidate=60" \
    --content-type "text/html; charset=utf-8" \
    --delete \
    --profile "$AWS_PROFILE"
  ok "HTML synced."

  # 2. CSS — long cache (1 year, immutable)
  log "Syncing CSS (max-age=31536000)..."
  aws s3 sync "$SCRIPT_DIR/css" "$S3_URL/css/" \
    --cache-control "public, max-age=31536000, immutable" \
    --profile "$AWS_PROFILE"
  ok "CSS synced."

  # 3. JavaScript — long cache (1 year, immutable)
  log "Syncing JavaScript (max-age=31536000)..."
  aws s3 sync "$SCRIPT_DIR/js" "$S3_URL/js/" \
    --cache-control "public, max-age=31536000, immutable" \
    --profile "$AWS_PROFILE"
  ok "JS synced."

  # 4. Images — long cache (1 year, immutable)
  log "Syncing images (max-age=31536000)..."
  aws s3 sync "$SCRIPT_DIR/img" "$S3_URL/img/" \
    --cache-control "public, max-age=31536000, immutable" \
    --profile "$AWS_PROFILE"
  ok "Images synced."

  # 5. Documents — no cache (always fresh)
  #    PDFs and downloadable files should always be current.
  if [[ -d "$SCRIPT_DIR/docs" ]]; then
    log "Syncing documents (no-cache)..."
    aws s3 sync "$SCRIPT_DIR/docs" "$S3_URL/docs/" \
      --cache-control "no-cache, no-store, must-revalidate" \
      --profile "$AWS_PROFILE"
    ok "Documents synced."
  fi

fi

# ── CLOUDFRONT INVALIDATION ───────────────────────────────────
if [[ "$SKIP_INVALIDATION" == false ]]; then

  log "Creating CloudFront invalidation for distribution $CF_DISTRIBUTION_ID..."
  info "Invalidating /* (all paths — 1000 free paths/month)"

  INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$CF_DISTRIBUTION_ID" \
    --paths "/*" \
    --profile "$AWS_PROFILE" \
    --query 'Invalidation.Id' \
    --output text)

  ok "Invalidation created: $INVALIDATION_ID"
  log "Waiting for invalidation to complete (this can take 1–3 minutes)..."

  aws cloudfront wait invalidation-completed \
    --distribution-id "$CF_DISTRIBUTION_ID" \
    --id "$INVALIDATION_ID" \
    --profile "$AWS_PROFILE"

  ok "Invalidation complete."

fi

# ── DONE ─────────────────────────────────────────────────────
echo ""
echo "  ✓ Deployment complete!"
echo "    https://tecdive.rs"
echo ""

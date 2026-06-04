#!/usr/bin/env bash
# ============================================================
#  TecDive AWS Infrastructure Setup — ONE-TIME SCRIPT
#  Run steps in order. Each step depends on the previous.
#  Run via Git Bash or WSL on Windows.
# ============================================================
set -euo pipefail

# ── CONFIGURATION ─────────────────────────────────────────────
BUCKET_NAME="tecdive-rs-static"
AWS_REGION="eu-central-1"        # Frankfurt — closest to Serbia
DOMAIN="tecdive.rs"
DOMAIN_WWW="www.tecdive.rs"
AWS_PROFILE="${AWS_PROFILE:-default}"   # override with: AWS_PROFILE=myprofile ./aws-setup.sh

log() { echo -e "\n\033[1;34m[setup]\033[0m $*"; }
warn() { echo -e "\033[1;33m[warn]\033[0m $*"; }
ok() { echo -e "\033[1;32m[ok]\033[0m $*"; }

# ── STEP 1: ACM CERTIFICATE (must be us-east-1 for CloudFront) ──
log "STEP 1 — Requesting ACM certificate in us-east-1..."

CERT_ARN=$(aws acm request-certificate \
  --domain-name "$DOMAIN" \
  --subject-alternative-names "$DOMAIN_WWW" \
  --validation-method DNS \
  --region us-east-1 \
  --profile "$AWS_PROFILE" \
  --query 'CertificateArn' \
  --output text)

ok "Certificate ARN: $CERT_ARN"

log "Fetching DNS validation records..."
aws acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --region us-east-1 \
  --profile "$AWS_PROFILE" \
  --query 'Certificate.DomainValidationOptions[].{Domain:DomainName,Name:ResourceRecord.Name,Value:ResourceRecord.Value}' \
  --output table

warn "ACTION REQUIRED: Add the CNAME records above to your DNS provider."
warn "Wait until certificate Status = ISSUED before continuing."
warn "Check status with:"
echo "  aws acm describe-certificate --certificate-arn \"$CERT_ARN\" --region us-east-1 --profile \"$AWS_PROFILE\" --query 'Certificate.Status' --output text"
echo ""
read -rp "Press ENTER once the certificate is ISSUED to continue..."

# Verify certificate is issued
STATUS=$(aws acm describe-certificate \
  --certificate-arn "$CERT_ARN" \
  --region us-east-1 \
  --profile "$AWS_PROFILE" \
  --query 'Certificate.Status' \
  --output text)

if [[ "$STATUS" != "ISSUED" ]]; then
  warn "Certificate status is '$STATUS', not ISSUED. Exiting."
  exit 1
fi
ok "Certificate is ISSUED."

# ── STEP 2: S3 BUCKET (private, no public access) ────────────
log "STEP 2 — Creating S3 bucket: $BUCKET_NAME in $AWS_REGION..."

aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION" \
  --profile "$AWS_PROFILE"

# Block all public access
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile "$AWS_PROFILE"

# Enable versioning (optional but useful for accidental overwrites)
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled \
  --profile "$AWS_PROFILE"

ok "S3 bucket created and secured."

# ── STEP 3: CLOUDFRONT ORIGIN ACCESS CONTROL ────────────────
log "STEP 3 — Creating CloudFront Origin Access Control..."

OAC_ID=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config '{
    "Name": "tecdive-rs-oac",
    "Description": "OAC for tecdive.rs S3 bucket",
    "SigningProtocol": "sigv4",
    "SigningBehavior": "always",
    "OriginAccessControlOriginType": "s3"
  }' \
  --profile "$AWS_PROFILE" \
  --query 'OriginAccessControl.Id' \
  --output text)

ok "OAC ID: $OAC_ID"

# ── STEP 4: CLOUDFRONT DISTRIBUTION ─────────────────────────
log "STEP 4 — Creating CloudFront distribution..."

CALLER_REF="tecdive-rs-$(date +%s)"
S3_DOMAIN="${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com"

# Write config to temp file
cat > /tmp/cf-distribution-config.json << EOF
{
  "CallerReference": "${CALLER_REF}",
  "Aliases": {
    "Quantity": 2,
    "Items": ["${DOMAIN}", "${DOMAIN_WWW}"]
  },
  "DefaultRootObject": "index.html",
  "Comment": "tecdive.rs static site",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-tecdive-rs",
        "DomainName": "${S3_DOMAIN}",
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        },
        "OriginAccessControlId": "${OAC_ID}"
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-tecdive-rs",
    "ViewerProtocolPolicy": "redirect-to-https",
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "Compress": true,
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    }
  },
  "CustomErrorResponses": {
    "Quantity": 2,
    "Items": [
      {
        "ErrorCode": 403,
        "ResponsePagePath": "/404.html",
        "ResponseCode": "404",
        "ErrorCachingMinTTL": 10
      },
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/404.html",
        "ResponseCode": "404",
        "ErrorCachingMinTTL": 10
      }
    ]
  },
  "PriceClass": "PriceClass_100",
  "Enabled": true,
  "HttpVersion": "http2and3",
  "IsIPV6Enabled": true,
  "ViewerCertificate": {
    "ACMCertificateArn": "${CERT_ARN}",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  }
}
EOF

CF_OUTPUT=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cf-distribution-config.json \
  --profile "$AWS_PROFILE" \
  --query 'Distribution.{Id:Id,DomainName:DomainName}' \
  --output json)

CF_ID=$(echo "$CF_OUTPUT"     | python3 -c "import sys,json; print(json.load(sys.stdin)['Id'])")
CF_DOMAIN=$(echo "$CF_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['DomainName'])")

ok "CloudFront Distribution ID: $CF_ID"
ok "CloudFront Domain: $CF_DOMAIN"

# ── STEP 5: S3 BUCKET POLICY (grant OAC read access) ────────
log "STEP 5 — Attaching bucket policy for CloudFront OAC..."

ACCOUNT_ID=$(aws sts get-caller-identity \
  --profile "$AWS_PROFILE" \
  --query 'Account' \
  --output text)

CF_ARN="arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${CF_ID}"

aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --profile "$AWS_PROFILE" \
  --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Sid\": \"AllowCloudFrontOAC\",
        \"Effect\": \"Allow\",
        \"Principal\": {
          \"Service\": \"cloudfront.amazonaws.com\"
        },
        \"Action\": \"s3:GetObject\",
        \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/*\",
        \"Condition\": {
          \"StringEquals\": {
            \"AWS:SourceArn\": \"${CF_ARN}\"
          }
        }
      }
    ]
  }"

ok "Bucket policy attached."

# ── STEP 6: SAVE VALUES FOR deploy.sh ────────────────────────
log "STEP 6 — Saving deployment config..."

cat > "$(dirname "$0")/.deploy-config" << EOF
# Auto-generated by aws-setup.sh — used by deploy.sh
BUCKET_NAME="${BUCKET_NAME}"
CF_DISTRIBUTION_ID="${CF_ID}"
AWS_PROFILE="${AWS_PROFILE}"
EOF

ok "Saved .deploy-config"

# ── SUMMARY ──────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  SETUP COMPLETE"
echo "============================================================"
echo ""
echo "  S3 Bucket:          $BUCKET_NAME"
echo "  CloudFront ID:      $CF_ID"
echo "  CloudFront domain:  $CF_DOMAIN"
echo ""
echo "  NEXT STEP — DNS Configuration:"
echo "  ─────────────────────────────"
echo "  Add these records at your DNS provider (registrar / Route 53):"
echo ""
echo "  Option A — Route 53 (A ALIAS):"
echo "    ${DOMAIN}      → ALIAS  ${CF_DOMAIN}"
echo "    ${DOMAIN_WWW}  → ALIAS  ${CF_DOMAIN}"
echo "    (Route 53 CloudFront hosted zone ID: Z2FDTNDATAQYW2)"
echo ""
echo "  Option B — External registrar (CNAME / ALIAS):"
echo "    ${DOMAIN}      → CNAME / ALIAS / ANAME  ${CF_DOMAIN}"
echo "    ${DOMAIN_WWW}  → CNAME                  ${CF_DOMAIN}"
echo "    NOTE: Apex (${DOMAIN}) CNAME is not standard DNS."
echo "          Use ALIAS/ANAME if your registrar supports it,"
echo "          or migrate DNS to Route 53."
echo ""
echo "  CloudFront deployment takes 5–15 minutes."
echo "  Run ./deploy.sh once DNS propagates."
echo "============================================================"

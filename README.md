# Tec Dive Subotica

Statični sajt za ronilački klub Tec Dive Subotica. Hostovan na AWS S3 + CloudFront sa automatskim deployom putem GitHub Actions.

**URL:** https://tecdive.rs

---

## Tehnologije

- HTML / CSS / JavaScript — bez frameworka
- AWS S3 (hosting), CloudFront (CDN), Route53 (DNS), ACM (SSL)
- Terraform — infrastruktura kao kod
- GitHub Actions — CI/CD

## Struktura

```
tecdive/
├── site/               # Web fajlovi (jedino što se deploya na S3)
│   ├── index.html
│   ├── o-nama.html
│   ├── obuke.html
│   ├── kontakt.html
│   ├── dokumenti.html
│   ├── galerija.html
│   ├── 404.html
│   ├── css/style.css
│   ├── js/main.js
│   ├── img/
│   └── docs/
├── terraform/          # AWS infrastruktura
├── .github/workflows/  # CI/CD pipeline
├── CLAUDE.md           # Dokumentacija za Claude Code
└── manual.md           # Koraci za ručne operacije
```

## Deploy

Svaki push na `dev` branch automatski pokreće GitHub Actions pipeline koji:
1. Sinkronizuje `site/` sa S3 bucketom
2. Invalidira CloudFront cache

```bash
git push origin dev
```

Za ručni deploy: GitHub → Actions → deploy.yml → Run workflow.

## Branching

| Branch | Svrha |
|--------|-------|
| `dev` | Radni branch — push ovdje pokreće deploy |
| `master` | Stabilna produkcija |

Sve promjene idu na `dev`. `master` se ne dirá direktno.

## Lokalni razvoj

```bash
cd site
npx serve .
# Sajt dostupan na http://localhost:3000
```

## Infrastruktura (Terraform)

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Za detaljan setup vidi [`manual.md`](manual.md).

## GitHub Secrets (potrebni za CI/CD)

| Secret | Opis |
|--------|------|
| `AWS_ACCESS_KEY_ID` | IAM pristupni ključ |
| `AWS_SECRET_ACCESS_KEY` | IAM tajni ključ |
| `AWS_REGION` | `eu-central-1` |
| `S3_BUCKET_NAME` | Iz `terraform output s3_bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID` | Iz `terraform output cloudfront_distribution_id` |

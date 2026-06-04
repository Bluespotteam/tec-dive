# TecDive — CLAUDE.md

Projektna dokumentacija za Claude Code. Drži ovaj fajl ažurnim pri svakoj većoj promjeni.

---

## O projektu

**Naziv:** Tec Dive Subotica  
**Domen:** https://tecdive.rs  
**Jezik sajta:** Srpski  
**Tip:** Statični HTML/CSS/JS sajt — bez frameworka  
**GitHub:** https://github.com/Bluespotteam/tec-dive  
**Referentni projekt (arhitektura):** https://github.com/Bluespotteam/djordje.vucinac

---

## Struktura repozitorija

```
tec-dive/
├── site/                   # Web fajlovi (jedini koji se deployuju na S3)
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
├── terraform/              # IaC — sva AWS infrastruktura
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── .github/
│   └── workflows/
│       └── deploy.yml      # CI/CD pipeline
├── deploy.sh               # Manuelni deploy (zastarjelo, zamijenjeno CI/CD)
├── aws-setup.sh            # Jednokratni setup (zastarjelo, zamijenjeno Terraformom)
├── CLAUDE.md               # Ovaj fajl
├── manual.md               # Koraci za ručne operacije
└── .gitignore
```

---

## Git branching

| Branch | Svrha |
|--------|-------|
| `dev`  | Primarni radni branch — svaki push okida CI/CD deploy |
| `master` | Stabilna produkcija — merge sa deva kad je spremno |

**Pravilo:** Sve promjene idu na `dev`. `master` se ne dirá direktno.

---

## AWS infrastruktura

| Resurs | Vrijednost |
|--------|-----------|
| S3 bucket (sajt) | `tecdive-rs-static` |
| S3 bucket (Terraform state) | `tecdive-terraform-state` |
| AWS region | `eu-central-1` (Frankfurt) |
| ACM certifikat region | `us-east-1` (AWS zahtjev za CloudFront) |
| CloudFront price class | `PriceClass_100` (US + Europa) |
| Domeni na CloudFrontu | `tecdive.rs`, `www.tecdive.rs` |

### Terraform resursi (terraform/main.tf)

- `aws_s3_bucket.site` — privatni bucket, pristup samo preko OAC
- `aws_s3_bucket_versioning.site` — versioning enabled
- `aws_s3_bucket_public_access_block.site` — sve blokado
- `aws_cloudfront_origin_access_control.site` — SigV4
- `aws_acm_certificate.site` — wildcard cert (`tecdive.rs` + `*.tecdive.rs`)
- `aws_route53_zone.site` — hosted zone za `tecdive.rs`
- `aws_route53_record.acm_validation` — DNS validacija certifikata
- `aws_acm_certificate_validation.site` — čeka validaciju
- `aws_cloudfront_distribution.site` — CDN sa HTTPS, kompresija, custom 404
- `aws_s3_bucket_policy.site` — dozvoljava samo CloudFront OAC
- `aws_route53_record.apex` — `tecdive.rs` → CloudFront alias
- `aws_route53_record.www` — `www.tecdive.rs` → CloudFront alias

### Terraform state backend

```hcl
backend "s3" {
  bucket = "tecdive-terraform-state"
  key    = "production/terraform.tfstate"
  region = "eu-central-1"
}
```

State bucket mora biti kreiran ručno jednom — vidi `manual.md`.

---

## CI/CD pipeline (.github/workflows/deploy.yml)

**Trigger:** Push na `dev` branch ili manuelni dispatch  
**Concurrency:** Cancel-in-progress (nema paralelnih deploya)

### Koraci

1. `actions/checkout@v4`
2. `aws-actions/configure-aws-credentials@v4` — autentifikacija putem GitHub Secrets
3. `aws s3 sync site/ s3://$S3_BUCKET_NAME --delete --cache-control "max-age=86400"`
4. CloudFront invalidacija `/*`

### GitHub Secrets (moraju biti postavljeni u repo settings)

| Secret | Vrijednost |
|--------|-----------|
| `AWS_ACCESS_KEY_ID` | IAM pristupni ključ |
| `AWS_SECRET_ACCESS_KEY` | IAM tajni ključ |
| `AWS_REGION` | `eu-central-1` |
| `S3_BUCKET_NAME` | Iz `terraform output s3_bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID` | Iz `terraform output cloudfront_distribution_id` |

---

## Terraform varijable (terraform/variables.tf)

| Varijabla | Default |
|-----------|---------|
| `project` | `"tecdive"` |
| `environment` | `"production"` |
| `domain_name` | `"tecdive.rs"` |
| `zone_name` | `"tecdive.rs"` |
| `aws_region` | `"eu-central-1"` |

---

## Terraform outputi

| Output | Svrha |
|--------|-------|
| `s3_bucket_name` | → GitHub Secret `S3_BUCKET_NAME` |
| `cloudfront_distribution_id` | → GitHub Secret `CLOUDFRONT_DISTRIBUTION_ID` |
| `cloudfront_url` | CloudFront URL (prije DNS promjene) |
| `site_url` | `https://tecdive.rs` |
| `route53_name_servers` | NS recordi za zamjenu na registraru |
| `acm_certificate_arn` | ARN certifikata |

---

## Manuelni deploy (zastarjelo)

`deploy.sh` je ostao za referencu — njega **ne koristiti** za produkciju.  
CI/CD pipeline je jedini način deploya.

---

## Napomene

- `.csv` fajlovi su u `.gitignore` — nikad ne commitovati AWS kredencijale
- Terraform state fajlovi su u `.gitignore` — state se čuva u S3
- DNS serveri će biti zamijenjeni na Route53 NS recordse (vidi `manual.md`)
- ACM certifikat se automatski validira putem Route53 DNS zapisa koje Terraform kreira

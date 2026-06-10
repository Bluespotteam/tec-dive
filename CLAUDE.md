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
│   └── img/
├── Dokumenti/              # PDF fajlovi za stranicu Dokumenti — deployuju se na S3/docs/
├── terraform/              # IaC — sva AWS infrastruktura
├── .github/workflows/      # CI/CD pipeline
├── CLAUDE.md               # Ovaj fajl
├── manual.md               # Koraci za ručne operacije
└── README.md
```

---

## Git branching

| Branch | Svrha |
|--------|-------|
| `dev` | Primarni radni branch — svaki push okida CI/CD deploy |
| `master` | Stabilna produkcija — merge sa deva kad je spremno |

**Pravilo:** Sve promjene idu na `dev`. `master` se ne dirá direktno.

---

## AWS infrastruktura

| Resurs | Vrijednost |
|--------|-----------|
| S3 bucket (sajt) | `tecdive-rs-static` |
| S3 bucket (Terraform state) | `tecdive-terraform-state` |
| AWS region | `eu-central-1` |
| ACM certifikat region | `us-east-1` (AWS zahtjev za CloudFront) |
| Domeni na CloudFrontu | `tecdive.rs`, `www.tecdive.rs` |

Terraform resursi i outputi su u `terraform/` — vidi kod direktno.  
Za setup korake vidi `manual.md`.

---

## CI/CD pipeline

**Trigger:** Push na `dev` branch ili manuelni dispatch  
**Fajl:** `.github/workflows/deploy.yml`

Pipeline sinkronizuje `site/` na S3 root i `Dokumenti/` na S3 `docs/` prefiks, zatim invalidira CloudFront cache.

### GitHub Secrets

| Secret | Vrijednost |
|--------|-----------|
| `AWS_ACCESS_KEY_ID` | IAM pristupni ključ |
| `AWS_SECRET_ACCESS_KEY` | IAM tajni ključ |
| `AWS_REGION` | `eu-central-1` |
| `S3_BUCKET_NAME` | Iz `terraform output s3_bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID` | Iz `terraform output cloudfront_distribution_id` |

---

## Napomene

- PDF dokumenti idu u `Dokumenti/` — CI/CD ih deploya na `/docs/` putanju na S3
- `.csv` fajlovi su u `.gitignore` — nikad ne commitovati AWS kredencijale
- Terraform state je u `.gitignore` — state se čuva u S3 bucketu
- `deploy.sh` i `aws-setup.sh` su zastarjeli — ne koristiti za produkciju

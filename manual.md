# TecDive — Ručne operacije

Sve što se ne može automatizovati. Dopunjavati ovaj fajl sa svakim novim ručnim korakom.

---

## 1. Jednokratni setup (raditi jednom, po redu)

### 1.1 Kreirati Terraform state bucket

State bucket mora postojati **prije** `terraform init`.

```bash
aws s3api create-bucket \
  --bucket tecdive-terraform-state \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

aws s3api put-bucket-versioning \
  --bucket tecdive-terraform-state \
  --versioning-configuration Status=Enabled
```

### 1.2 Pokrenuti Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

`terraform apply` kreira: S3 bucket, CloudFront distribuciju, ACM certifikat, Route53 zonu i DNS recordse.  
Može trajati 5–15 minuta (CloudFront + ACM validacija).

### 1.3 Zamijeniti DNS servere na registraru

Nakon `terraform apply`, uzeti NS recordse:

```bash
terraform output route53_name_servers
```

Dobićeš 4 NS adrese (npr. `ns-123.awsdns-12.com`).  
Otići na registrar gdje je kupljen domen `tecdive.rs` i zamijeniti postojeće NS recordse sa ovima.

**DNS propagacija:** 24–48 sati.

### 1.4 Dodati GitHub Secrets

Ići na: **GitHub → Bluespotteam/tec-dive → Settings → Secrets and variables → Actions**

Dodati sljedeće secretove:

| Secret | Kako dobiti |
|--------|------------|
| `AWS_ACCESS_KEY_ID` | IAM → Users → Bluespotteam → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | Isto (čuva se samo pri kreiranju) |
| `AWS_REGION` | Upisati: `eu-central-1` |
| `S3_BUCKET_NAME` | `terraform output s3_bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `terraform output cloudfront_distribution_id` |

Nakon ovoga, svaki push na `dev` branch automatski deploya sajt.

### 1.5 Verifikacija

```bash
# Provjeriti CloudFront URL (radi odmah, bez DNS)
terraform output cloudfront_url

# Provjeriti da sajt radi na custom domenu (nakon DNS propagacije)
curl -I https://tecdive.rs
```

---

## 2. Rekurentne operacije

### 2.1 Manuelni deploy (bypass CI/CD)

Ako treba deployovati bez pusha na git:

```bash
# U GitHub Actions — kliknuti "Run workflow" na dev branchu
# Ili lokalno (zastarjelo):
./deploy.sh
```

### 2.2 Invalidacija CloudFront cachea

```bash
aws cloudfront create-invalidation \
  --distribution-id <CF_DISTRIBUTION_ID> \
  --paths "/*"
```

### 2.3 Ažuriranje infrastrukture (Terraform)

```bash
cd terraform
terraform plan    # pregled promjena
terraform apply   # primjena
```

### 2.4 Uništavanje infrastrukture

```bash
cd terraform
terraform destroy
```

**Pažnja:** Briše sve AWS resurse uključujući S3 bucket sa fajlovima.

---

## 3. AWS IAM — novi pristupni ključevi

Ako treba zamijeniti AWS kredencijale:

1. Ići na AWS Console → IAM → Users → Bluespotteam → Security credentials
2. Kreirati novi Access key
3. Ažurirati GitHub Secrets: `AWS_ACCESS_KEY_ID` i `AWS_SECRET_ACCESS_KEY`
4. Deaktivirati i obrisati stari ključ

---

## 4. Status

| Korak | Status |
|-------|--------|
| State bucket kreiran | [ ] |
| `terraform apply` uspješno | [ ] |
| DNS serveri zamijenjeni na registraru | [ ] |
| GitHub Secrets postavljeni | [ ] |
| CI/CD pipeline testiran (push na dev) | [ ] |
| `https://tecdive.rs` radi sa HTTPS | [ ] |

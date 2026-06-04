output "s3_bucket_name" {
  description = "S3 bucket name — use as S3_BUCKET_NAME GitHub secret"
  value       = aws_s3_bucket.site.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.site.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — use as CLOUDFRONT_DISTRIBUTION_ID GitHub secret"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_url" {
  description = "CloudFront domain name (before custom domain is active)"
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "site_url" {
  description = "Live site URL"
  value       = "https://${var.domain_name}"
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.site.arn
}

output "route53_name_servers" {
  description = "Route53 NS records — replace these on your domain registrar"
  value       = aws_route53_zone.site.name_servers
}

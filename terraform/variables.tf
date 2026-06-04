variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "tecdive"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Primary domain name for the site (e.g. tecdive.rs)"
  type        = string
  default     = "tecdive.rs"
}

variable "zone_name" {
  description = "Route53 hosted zone name (apex domain)"
  type        = string
  default     = "tecdive.rs"
}

variable "aws_region" {
  description = "AWS region for S3, CloudFront, and Route53 resources"
  type        = string
  default     = "eu-central-1"
}

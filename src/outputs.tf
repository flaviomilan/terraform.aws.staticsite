output "name_servers" {
  description = "Name servers for the Route 53 hosted zone. Configure these at your domain registrar."
  value       = aws_route53_zone.public_zone.name_servers
}

output "bucket_id" {
  description = "The S3 bucket name."
  value       = var.domain_enabled ? aws_s3_bucket.s3_bucket[0].id : ""
}

output "bucket_arn" {
  description = "The S3 bucket ARN."
  value       = var.domain_enabled ? aws_s3_bucket.s3_bucket[0].arn : ""
}

output "bucket_regional_domain_name" {
  description = "The S3 bucket regional domain name."
  value       = var.domain_enabled ? aws_s3_bucket.s3_bucket[0].bucket_regional_domain_name : ""
}

output "cloudfront_distribution_id" {
  description = "The CloudFront distribution ID. Use for cache invalidation."
  value       = var.domain_enabled ? aws_cloudfront_distribution.s3_distribution[0].id : ""
}

output "cloudfront_domain_name" {
  description = "The CloudFront distribution domain name."
  value       = var.domain_enabled ? aws_cloudfront_distribution.s3_distribution[0].domain_name : ""
}

output "acm_certificate_arn" {
  description = "The ACM certificate ARN."
  value       = var.domain_enabled ? aws_acm_certificate.cert[0].arn : ""
}

output "site_url" {
  description = "The URL of the deployed site."
  value       = var.domain_enabled ? "https://${var.domain}" : ""
}

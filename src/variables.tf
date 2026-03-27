variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region where the resources will be provisioned. ACM certificates for CloudFront must be in us-east-1."

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "Must be a valid AWS region identifier (e.g., us-east-1)."
  }
}

variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket used for hosting your application files."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Must be a valid S3 bucket name (lowercase, 3-63 characters)."
  }
}

variable "domain" {
  type        = string
  description = "The domain name for your application (e.g., example.com)."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]+[a-z0-9]$", var.domain))
    error_message = "Must be a valid domain name."
  }
}

variable "files_path" {
  type        = string
  description = "The path to the static site files to be uploaded to the S3 bucket."
}

variable "domain_enabled" {
  type        = bool
  default     = false
  description = "Enable or disable the creation of domain-related resources (ACM, CloudFront, S3, WAF). Set to true after DNS nameservers are configured."
}

variable "enable_waf" {
  type        = bool
  default     = false
  description = "Enable AWS WAF for the CloudFront distribution. Adds protection against common web attacks. Note: WAF incurs additional costs (~$5/month + per-request charges)."
}

variable "project_name" {
  type        = string
  default     = "StaticSite"
  description = "Project name used for resource naming and tagging."
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment name for resource tagging."

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

variable "force_destroy_zone" {
  type        = bool
  default     = false
  description = "Allow destruction of the Route53 hosted zone even if it contains records. Use with caution in production."
}

variable "csp_policy" {
  type        = string
  default     = "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self';"
  description = "Content-Security-Policy header value. Customize based on your site's requirements."
}

variable "waf_rate_limit" {
  type        = number
  default     = 2000
  description = "Maximum number of requests per 5-minute period per IP address before WAF blocks the source."

  validation {
    condition     = var.waf_rate_limit >= 100 && var.waf_rate_limit <= 20000000
    error_message = "WAF rate limit must be between 100 and 20,000,000."
  }
}

variable "enable_monitoring" {
  type        = bool
  default     = true
  description = "Enable CloudWatch monitoring dashboards and alarms for CloudFront and WAF."
}

variable "notification_email" {
  type        = string
  default     = ""
  description = "Email address for CloudWatch alarm notifications. Leave empty to disable email alerts."
}

variable "minimum_tls_version" {
  type        = string
  default     = "TLSv1.2_2021"
  description = "Minimum TLS protocol version for CloudFront viewer connections."

  validation {
    condition     = contains(["TLSv1.2_2018", "TLSv1.2_2019", "TLSv1.2_2021"], var.minimum_tls_version)
    error_message = "TLS version must be one of: TLSv1.2_2018, TLSv1.2_2019, TLSv1.2_2021."
  }
}
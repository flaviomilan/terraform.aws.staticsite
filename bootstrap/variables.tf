variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for the state resources."
}

variable "state_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for Terraform state storage."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "Bucket name must be a valid S3 bucket name (lowercase, 3-63 chars)."
  }
}

variable "lock_table_name" {
  type        = string
  default     = "terraform-locks"
  description = "Name of the DynamoDB table for Terraform state locking."
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment name for resource tagging."
}

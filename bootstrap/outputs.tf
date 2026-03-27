output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state."
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB table for state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_config" {
  description = "Backend configuration snippet for main Terraform project."
  value       = <<-EOT
    Add this to your src/main.tf or use -backend-config flags:

    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "staticsite/terraform.tfstate"
        region         = "${var.aws_region}"
        encrypt        = true
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
      }
    }

    Or initialize with:
    terraform init \
      -backend-config="bucket=${aws_s3_bucket.terraform_state.id}" \
      -backend-config="key=staticsite/terraform.tfstate" \
      -backend-config="region=${var.aws_region}" \
      -backend-config="dynamodb_table=${aws_dynamodb_table.terraform_locks.name}" \
      -backend-config="encrypt=true"
  EOT
}

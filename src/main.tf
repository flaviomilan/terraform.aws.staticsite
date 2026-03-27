terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.38"
    }
  }

  # Default: local backend. For production, use the S3 backend below.
  # First run the bootstrap/ module to create the state infrastructure,
  # then switch to S3 backend with:
  #   terraform init \
  #     -backend-config="bucket=YOUR_STATE_BUCKET" \
  #     -backend-config="key=staticsite/terraform.tfstate" \
  #     -backend-config="region=us-east-1" \
  #     -backend-config="dynamodb_table=terraform-locks" \
  #     -backend-config="encrypt=true"
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}
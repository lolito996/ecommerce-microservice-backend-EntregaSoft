# Bootstrap Configuration for Terraform Backend
# This must be run FIRST to create the S3 bucket and DynamoDB table
# Usage:
#   cd infra/aws-backend-bootstrap
#   terraform init
#   terraform apply
#   
# After this, you can configure backend in other environments

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ecommerce-microservices"
      ManagedBy   = "Terraform"
      Environment = "shared"
      Purpose     = "backend-infrastructure"
    }
  }
}

# Random suffix to ensure globally unique bucket name
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

module "terraform_backend" {
  source = "../modules/aws-s3-backend"

  project_name         = var.project_name
  bucket_name          = "${var.project_name}-terraform-state-${random_string.suffix.result}"
  dynamodb_table_name  = "${var.project_name}-terraform-locks"
  create_backend_policy = true

  common_tags = {
    Project     = "ecommerce-microservices"
    ManagedBy   = "Terraform"
    Environment = "shared"
  }
}

# Create a configuration file with backend details
resource "local_file" "backend_config" {
  filename = "${path.module}/backend-config.txt"
  content  = <<-EOT
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                  Terraform Backend Configuration                         ║
    ╚══════════════════════════════════════════════════════════════════════════╝
    
    S3 Bucket:        ${module.terraform_backend.s3_bucket_id}
    DynamoDB Table:   ${module.terraform_backend.dynamodb_table_id}
    Region:           ${var.aws_region}
    
    ═══════════════════════════════════════════════════════════════════════════
    Backend Configuration Template
    ═══════════════════════════════════════════════════════════════════════════
    
    Add this to your backend.tf file in each environment:
    
    terraform {
      backend "s3" {
        bucket         = "${module.terraform_backend.s3_bucket_id}"
        key            = "<environment>/terraform.tfstate"  # e.g., "dev/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${module.terraform_backend.dynamodb_table_id}"
        encrypt        = true
      }
    }
    
    ═══════════════════════════════════════════════════════════════════════════
    Environment-specific keys:
    ═══════════════════════════════════════════════════════════════════════════
    
    Dev:   key = "dev/terraform.tfstate"
    Stage: key = "stage/terraform.tfstate"
    Prod:  key = "prod/terraform.tfstate"
    
    ═══════════════════════════════════════════════════════════════════════════
  EOT
}

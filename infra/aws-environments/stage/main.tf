# Staging Environment Configuration
# Mimics production but with smaller resources

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

  # Backend configuration - S3 remote state
  backend "s3" {
    bucket         = "ecommerce-terraform-state-n3pg459r"
    key            = "stage/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ecommerce-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CostCenter  = "Staging"
    }
  }
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/aws-vpc"

  environment            = var.environment
  project_name           = var.project_name
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  availability_zones     = var.availability_zones
  enable_nat_gateway     = var.enable_nat_gateway
  enable_flow_logs       = true
  flow_logs_retention_days = 14
  common_tags            = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/aws-security-groups"

  environment          = var.environment
  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  allowed_cidr_blocks  = var.allowed_cidr_blocks
  create_rds_sg        = true
  common_tags          = local.common_tags
}

# ECS Cluster Module
module "ecs" {
  source = "../../modules/aws-ecs"

  environment              = var.environment
  project_name             = var.project_name
  enable_container_insights = true
  capacity_providers       = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider = "FARGATE"
  log_retention_days       = 14
  common_tags              = local.common_tags
}

# Application Load Balancer Module
module "alb" {
  source = "../../modules/aws-alb"

  environment                = var.environment
  project_name               = var.project_name
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.public_subnet_ids
  security_group_ids         = [module.security_groups.alb_security_group_id]
  internal                   = false
  enable_deletion_protection = false
  enable_https               = var.enable_https
  certificate_arn            = var.certificate_arn
  common_tags                = local.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/aws-rds"

  environment             = var.environment
  project_name            = var.project_name
  subnet_ids              = module.vpc.private_subnet_ids
  security_group_ids      = [module.security_groups.rds_security_group_id]
  instance_class          = "db.t3.small"
  allocated_storage       = 50
  max_allocated_storage   = 200
  multi_az                = false
  backup_retention_period = 7
  skip_final_snapshot     = false
  deletion_protection     = false
  common_tags             = local.common_tags
}

# Production Environment Configuration
# High availability with multi-AZ, enhanced monitoring, and security

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
    key            = "prod/terraform.tfstate"
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
      CostCenter  = "Production"
      Compliance  = "PCI-DSS"
    }
  }
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Critical    = "true"
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/aws-vpc"

  environment              = var.environment
  project_name             = var.project_name
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs     = var.private_subnet_cidrs
  availability_zones       = var.availability_zones
  enable_nat_gateway       = true
  enable_flow_logs         = true
  flow_logs_retention_days = 30
  common_tags              = local.common_tags
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

  environment               = var.environment
  project_name              = var.project_name
  enable_container_insights = true
  capacity_providers        = ["FARGATE"]
  default_capacity_provider = "FARGATE"
  log_retention_days        = 30
  common_tags               = local.common_tags
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
  enable_deletion_protection = true
  enable_https               = var.enable_https
  certificate_arn            = var.certificate_arn
  ssl_policy                 = "ELBSecurityPolicy-TLS-1-2-2017-01"
  common_tags                = local.common_tags
}

# RDS Module - Production with Multi-AZ
module "rds" {
  source = "../../modules/aws-rds"

  environment             = var.environment
  project_name            = var.project_name
  subnet_ids              = module.vpc.private_subnet_ids
  security_group_ids      = [module.security_groups.rds_security_group_id]
  instance_class          = var.rds_instance_class
  allocated_storage       = 100
  max_allocated_storage   = 500
  multi_az                = true
  backup_retention_period = 30
  skip_final_snapshot     = false
  deletion_protection     = true
  storage_encrypted       = true
  common_tags             = local.common_tags
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${var.environment}-${var.project_name}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when ALB response time exceeds 1 second"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = module.alb.alb_arn
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.environment}-${var.project_name}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when RDS CPU exceeds 80%"

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id
  }

  tags = local.common_tags
}

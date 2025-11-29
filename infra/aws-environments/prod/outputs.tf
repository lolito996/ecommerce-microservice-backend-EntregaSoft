output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "api_gateway_target_group_arn" {
  description = "API Gateway target group ARN"
  value       = module.alb.api_gateway_target_group_arn
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database password"
  value       = module.rds.db_password_secret_arn
  sensitive   = true
}

output "environment_summary" {
  description = "Environment summary"
  value       = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                    Production Environment Ready                          ║
    ╚══════════════════════════════════════════════════════════════════════════╝
    
    Environment:     ${var.environment}
    Region:          ${var.aws_region}
    VPC ID:          ${module.vpc.vpc_id}
    ECS Cluster:     ${module.ecs.cluster_name}
    
    Load Balancer:   ${module.alb.alb_dns_name}
    HTTPS:           ${var.enable_https ? "Enabled" : "Disabled"}
    
    API Gateway:     ${var.enable_https ? "https" : "http"}://${module.alb.alb_dns_name}/api
    
    Database:        ${module.rds.db_endpoint}
    Multi-AZ:        Enabled
    Backups:         30 days retention
    DB Password:     Stored in AWS Secrets Manager
    
    High Availability:
    - Multi-AZ RDS deployment
    - Multiple availability zones (${length(var.availability_zones)})
    - NAT Gateways in each AZ
    - ALB with health checks
    
    Security:
    - Deletion protection enabled
    - Encrypted storage
    - VPC Flow Logs enabled
    - CloudWatch alarms configured
    
    ═══════════════════════════════════════════════════════════════════════════
    IMPORTANT: This is a PRODUCTION environment
    - All changes should go through proper change management
    - Test in staging first
    - Monitor CloudWatch alarms
    ═══════════════════════════════════════════════════════════════════════════
    
  EOT
}

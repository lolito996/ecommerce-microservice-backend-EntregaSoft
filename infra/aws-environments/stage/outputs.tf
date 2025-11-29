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
    ║                     Staging Environment Ready                            ║
    ╚══════════════════════════════════════════════════════════════════════════╝
    
    Environment:     ${var.environment}
    Region:          ${var.aws_region}
    VPC ID:          ${module.vpc.vpc_id}
    ECS Cluster:     ${module.ecs.cluster_name}
    
    Load Balancer:   ${module.alb.alb_dns_name}
    
    API Gateway:     http://${module.alb.alb_dns_name}/api
    Eureka:          http://${module.alb.alb_dns_name}:8761
    Prometheus:      http://${module.alb.alb_dns_name}:9090
    Grafana:         http://${module.alb.alb_dns_name}:3000
    
    Database:        ${module.rds.db_endpoint}
    DB Password:     Stored in AWS Secrets Manager
    
    ═══════════════════════════════════════════════════════════════════════════
    Next Steps:
    1. Deploy microservices to ECS
    2. Run integration tests
    3. Verify with QA team before promoting to production
    ═══════════════════════════════════════════════════════════════════════════
    
  EOT
}

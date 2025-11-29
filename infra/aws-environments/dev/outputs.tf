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

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = module.ecs.task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = module.ecs.task_role_arn
}

output "db_endpoint" {
  description = "RDS endpoint"
  value       = var.enable_rds ? module.rds[0].db_endpoint : "RDS not enabled"
}

output "environment_summary" {
  description = "Environment summary"
  value       = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                    Development Environment Ready                         ║
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
    
    Database:        ${var.enable_rds ? module.rds[0].db_endpoint : "Disabled (using local)"}
    
    ═══════════════════════════════════════════════════════════════════════════
    Next Steps:
    1. Deploy microservices to ECS
    2. Configure DNS (optional)
    3. Set up CI/CD pipeline
    ═══════════════════════════════════════════════════════════════════════════
    
  EOT
}

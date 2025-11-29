output "service_discovery_namespace_id" {
  description = "Service Discovery namespace ID"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "service_discovery_namespace_name" {
  description = "Service Discovery namespace name"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "service_discovery_service_id" {
  description = "Eureka service ID"
  value       = aws_ecs_service.service_discovery.id
}

output "cloud_config_service_id" {
  description = "Cloud Config service ID"
  value       = aws_ecs_service.cloud_config.id
}

output "api_gateway_service_id" {
  description = "API Gateway service ID"
  value       = aws_ecs_service.api_gateway.id
}

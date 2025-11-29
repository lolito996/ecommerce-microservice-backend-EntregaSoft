output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS listener ARN"
  value       = var.enable_https ? aws_lb_listener.https[0].arn : null
}

output "api_gateway_target_group_arn" {
  description = "API Gateway target group ARN"
  value       = aws_lb_target_group.api_gateway.arn
}

output "service_discovery_target_group_arn" {
  description = "Service Discovery target group ARN"
  value       = aws_lb_target_group.service_discovery.arn
}

output "prometheus_target_group_arn" {
  description = "Prometheus target group ARN"
  value       = aws_lb_target_group.prometheus.arn
}

output "grafana_target_group_arn" {
  description = "Grafana target group ARN"
  value       = aws_lb_target_group.grafana.arn
}

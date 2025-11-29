variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ECS tasks security group ID"
  type        = string
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "docker_registry" {
  description = "Docker registry (Docker Hub username or ECR registry)"
  type        = string
  default     = "alejomunoz"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

# Target Groups
variable "api_gateway_target_group_arn" {
  description = "API Gateway target group ARN"
  type        = string
}

variable "service_discovery_target_group_arn" {
  description = "Service Discovery target group ARN"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB listener ARN"
  type        = string
}

# Service Counts
variable "service_discovery_count" {
  description = "Number of Service Discovery tasks"
  type        = number
  default     = 1
}

variable "config_count" {
  description = "Number of Config Server tasks"
  type        = number
  default     = 1
}

variable "gateway_count" {
  description = "Number of API Gateway tasks"
  type        = number
  default     = 2
}

variable "microservice_count" {
  description = "Number of each microservice tasks"
  type        = number
  default     = 2
}

# CPU and Memory
variable "cpu_service_discovery" {
  description = "CPU units for Service Discovery"
  type        = number
  default     = 512
}

variable "memory_service_discovery" {
  description = "Memory for Service Discovery"
  type        = number
  default     = 1024
}

variable "cpu_config" {
  description = "CPU units for Config Server"
  type        = number
  default     = 512
}

variable "memory_config" {
  description = "Memory for Config Server"
  type        = number
  default     = 1024
}

variable "cpu_gateway" {
  description = "CPU units for API Gateway"
  type        = number
  default     = 512
}

variable "memory_gateway" {
  description = "Memory for API Gateway"
  type        = number
  default     = 1024
}

variable "cpu_microservice" {
  description = "CPU units for microservices"
  type        = number
  default     = 512
}

variable "memory_microservice" {
  description = "Memory for microservices"
  type        = number
  default     = 1024
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

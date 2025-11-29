# ECS Service Module
# Creates ECS Task Definitions and Services for microservices

locals {
  # Common environment variables for all services
  common_env_vars = [
    {
      name  = "SPRING_PROFILES_ACTIVE"
      value = var.environment
    },
    {
      name  = "SPRING_ZIPKIN_BASE_URL"
      value = "http://zipkin.${var.environment}.local:9411"
    },
    {
      name  = "EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE"
      value = "http://service-discovery.${var.environment}.local:8761/eureka/"
    },
    {
      name  = "JAVA_OPTS"
      value = "-Xmx512m -Xms256m -XX:+UseG1GC -XX:+UseContainerSupport"
    }
  ]
}

# Service Discovery (Eureka)
resource "aws_ecs_task_definition" "service_discovery" {
  family                   = "${var.environment}-service-discovery"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu_service_discovery
  memory                   = var.memory_service_discovery
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "service-discovery"
      image     = "${var.docker_registry}/service-discovery:${var.image_tag}"
      essential = true
      
      portMappings = [
        {
          containerPort = 8761
          protocol      = "tcp"
        }
      ]
      
      environment = concat(local.common_env_vars, [
        {
          name  = "EUREKA_INSTANCE_HOSTNAME"
          value = "service-discovery.${var.environment}.local"
        }
      ])
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8761/actuator/health || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 60
      }
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "service-discovery"
        }
      }
    }
  ])

  tags = var.common_tags
}

resource "aws_ecs_service" "service_discovery" {
  name            = "${var.environment}-service-discovery"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.service_discovery.arn
  desired_count   = var.service_discovery_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.service_discovery_target_group_arn
    container_name   = "service-discovery"
    container_port   = 8761
  }

  service_registries {
    registry_arn = aws_service_discovery_service.service_discovery.arn
  }

  depends_on = [var.alb_listener_arn]

  tags = var.common_tags
}

# Cloud Config Server
resource "aws_ecs_task_definition" "cloud_config" {
  family                   = "${var.environment}-cloud-config"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu_config
  memory                   = var.memory_config
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "cloud-config"
      image     = "${var.docker_registry}/cloud-config:${var.image_tag}"
      essential = true
      
      portMappings = [
        {
          containerPort = 9296
          protocol      = "tcp"
        }
      ]
      
      environment = local.common_env_vars
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9296/actuator/health || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 60
      }
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "cloud-config"
        }
      }
    }
  ])

  tags = var.common_tags
}

resource "aws_ecs_service" "cloud_config" {
  name            = "${var.environment}-cloud-config"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.cloud_config.arn
  desired_count   = var.config_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.cloud_config.arn
  }

  depends_on = [aws_ecs_service.service_discovery]

  tags = var.common_tags
}

# API Gateway
resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "${var.environment}-api-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu_gateway
  memory                   = var.memory_gateway
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "api-gateway"
      image     = "${var.docker_registry}/api-gateway:${var.image_tag}"
      essential = true
      
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      
      environment = concat(local.common_env_vars, [
        {
          name  = "SPRING_CONFIG_IMPORT"
          value = "optional:configserver:http://cloud-config.${var.environment}.local:9296/"
        }
      ])
      
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 5
        startPeriod = 90
      }
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api-gateway"
        }
      }
    }
  ])

  tags = var.common_tags
}

resource "aws_ecs_service" "api_gateway" {
  name            = "${var.environment}-api-gateway"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.api_gateway.arn
  desired_count   = var.gateway_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.api_gateway_target_group_arn
    container_name   = "api-gateway"
    container_port   = 8080
  }

  service_registries {
    registry_arn = aws_service_discovery_service.api_gateway.arn
  }

  depends_on = [
    aws_ecs_service.service_discovery,
    aws_ecs_service.cloud_config
  ]

  tags = var.common_tags
}

# Service Discovery (AWS Cloud Map)
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.environment}.local"
  description = "Private DNS namespace for ${var.environment} environment"
  vpc         = var.vpc_id

  tags = var.common_tags
}

resource "aws_service_discovery_service" "service_discovery" {
  name = "service-discovery"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "cloud_config" {
  name = "cloud-config"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "api_gateway" {
  name = "api-gateway"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

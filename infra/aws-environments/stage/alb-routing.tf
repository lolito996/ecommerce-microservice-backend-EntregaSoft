# ALB Target Groups y Listener Rules para Staging
# Este archivo configura el enrutamiento del ALB a los servicios ECS

# Obtener el ALB existente
data "aws_lb" "main" {
  name = "${var.environment}-ecommerce-alb"
}

# Obtener el listener HTTP existente (puerto 80)
data "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.main.arn
  port              = 80
}

# Obtener VPC
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-ecommerce-vpc"]
  }
}

# Target Group para API Gateway
resource "aws_lb_target_group" "api_gateway" {
  name     = "${var.environment}-ecommerce-api-gateway-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,404"
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-ecommerce-api-gateway-tg"
    }
  )
}

# Target Group para User Service
resource "aws_lb_target_group" "user_service" {
  name     = "${var.environment}-ecommerce-user-svc-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,404"
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-ecommerce-user-service-tg"
    }
  )
}

# Target Group para Product Service
resource "aws_lb_target_group" "product_service" {
  name     = "${var.environment}-ecommerce-product-svc-tg"
  port     = 8082
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,404"
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-ecommerce-product-service-tg"
    }
  )
}

# Target Group para Order Service
resource "aws_lb_target_group" "order_service" {
  name     = "${var.environment}-ecommerce-order-svc-tg"
  port     = 8083
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,404"
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-ecommerce-order-service-tg"
    }
  )
}

# Listener Rule para API Gateway (ruta raíz /api)
resource "aws_lb_listener_rule" "api_gateway" {
  listener_arn = data.aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/actuator/*"]
    }
  }
}

# Listener Rule para User Service
resource "aws_lb_listener_rule" "user_service" {
  listener_arn = data.aws_lb_listener.http.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_service.arn
  }

  condition {
    path_pattern {
      values = ["/users/*", "/user-service/*"]
    }
  }
}

# Listener Rule para Product Service
resource "aws_lb_listener_rule" "product_service" {
  listener_arn = data.aws_lb_listener.http.arn
  priority     = 102

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product_service.arn
  }

  condition {
    path_pattern {
      values = ["/products/*", "/product-service/*"]
    }
  }
}

# Listener Rule para Order Service
resource "aws_lb_listener_rule" "order_service" {
  listener_arn = data.aws_lb_listener.http.arn
  priority     = 103

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order_service.arn
  }

  condition {
    path_pattern {
      values = ["/orders/*", "/order-service/*"]
    }
  }
}

# Outputs
output "api_gateway_target_group_arn" {
  description = "ARN of API Gateway target group"
  value       = aws_lb_target_group.api_gateway.arn
}

output "user_service_target_group_arn" {
  description = "ARN of User Service target group"
  value       = aws_lb_target_group.user_service.arn
}

output "product_service_target_group_arn" {
  description = "ARN of Product Service target group"
  value       = aws_lb_target_group.product_service.arn
}

output "order_service_target_group_arn" {
  description = "ARN of Order Service target group"
  value       = aws_lb_target_group.order_service.arn
}

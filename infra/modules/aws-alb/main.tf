# Application Load Balancer Module
# Creates ALB, target groups, and listeners

resource "aws_lb" "main" {
  name               = "${var.environment}-${var.project_name}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-alb"
    }
  )
}

# HTTP Listener (redirect to HTTPS if enabled, otherwise forward to API Gateway)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.enable_https ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.enable_https ? null : aws_lb_target_group.api_gateway.arn
  }
}

# HTTPS Listener (if enabled)
resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
}

# Target Group for API Gateway
resource "aws_lb_target_group" "api_gateway" {
  name        = "${var.environment}-${var.project_name}-api-gw-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 30
    interval            = 60
    path                = "/actuator/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-api-gateway-tg"
    }
  )
}

# Listener Rule for API Gateway - Forward all traffic
resource "aws_lb_listener_rule" "api_gateway" {
  listener_arn = var.enable_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# Target Group for Service Discovery (Eureka)
resource "aws_lb_target_group" "service_discovery" {
  name        = "${var.environment}-${var.project_name}-eureka-tg"
  port        = 8761
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 30
    interval            = 60
    path                = "/actuator/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-service-discovery-tg"
    }
  )
}

# Target Group for Prometheus
resource "aws_lb_target_group" "prometheus" {
  name        = "${var.environment}-${var.project_name}-prom-tg"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/-/healthy"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-prometheus-tg"
    }
  )
}

# Target Group for Grafana
resource "aws_lb_target_group" "grafana" {
  name        = "${var.environment}-${var.project_name}-graf-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-grafana-tg"
    }
  )
}

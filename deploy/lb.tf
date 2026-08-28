resource "aws_lb_target_group" "main" {
  name             = local.e3s_tg_name
  vpc_id           = var.vpc_id
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  port             = 4444
  target_type      = "instance"

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    enabled             = "true"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = 200
  }

  deregistration_delay = 660
}

resource "aws_lb" "main" {
  name               = local.e3s_alb_name
  subnets            = [var.public_subnet_1_id, var.public_subnet_2_id]
  security_groups    = [aws_security_group.e3s_server.id, aws_security_group.e3s_server_2.id, aws_security_group.e3s_server_3.id]
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  internal           = false
  idle_timeout       = 630
}

resource "aws_lb_listener" "http" {
  count             = var.cert == "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type  = "forward"
    order = 1
    forward {
      target_group {
        arn    = aws_lb_target_group.main.arn
        weight = 1
      }
      stickiness {
        enabled  = false
        duration = 3600
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.cert == "" ? 0 : 1
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.cert

  default_action {
    type  = "forward"
    order = 1
    forward {
      target_group {
        arn    = aws_lb_target_group.main.arn
        weight = 1
      }
      stickiness {
        enabled  = false
        duration = 3600
      }
    }
  }
}

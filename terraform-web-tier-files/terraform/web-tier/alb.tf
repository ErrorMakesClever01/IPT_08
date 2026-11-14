# All subnets of the VPC (the default VPC has one per availability zone)
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_lb" "web" {
  name               = "food-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.all.ids

  tags = { Name = "food-alb" }
}

# ---------- Target group 1: the web servers ----------
resource "aws_lb_target_group" "web" {
  name                 = "food-tg-web"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  # "/" on purpose. An API path would mark every server unhealthy if the database went down.
  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# ---------- Target group 2: food-app (serves the uploaded images) ----------
resource "aws_lb_target_group" "images" {
  name        = "food-tg-images"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "images_app" {
  target_group_arn = aws_lb_target_group.images.arn
  target_id        = var.app_instance_id
  port             = 3000
}

# ---------- Listener and routing ----------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_listener_rule" "images" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.images.arn
  }

  condition {
    path_pattern {
      values = ["/images/*"]
    }
  }
}

# ---------- Launch template: how every new web server is built ----------
resource "aws_launch_template" "web" {
  name                   = "food-web-lt"
  image_id               = var.ami_id
  instance_type          = var.web_instance_type
  key_name               = var.key_name
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id]
    delete_on_termination       = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # The boot script: installs Docker, reads the settings, pulls the images, starts the containers
  user_data = base64encode(file("${path.module}/user-data.sh"))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "food-web" }
  }

  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "food-web" }
  }
}

# ---------- Auto Scaling Group ----------
resource "aws_autoscaling_group" "web" {
  name                      = "food-web-asg"
  min_size                  = var.web_min_size
  max_size                  = var.web_max_size
  desired_capacity          = var.web_desired_capacity
  vpc_zone_identifier       = data.aws_subnets.all.ids
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300 # a new server needs 3 to 5 minutes to install Docker and start

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  # When the launch template changes, replace servers gradually, keeping at least half healthy
  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "food-web"
    propagate_at_launch = true
  }

  lifecycle {
    # The scaling policy changes the desired number by itself. Terraform must not fight it.
    ignore_changes = [desired_capacity]
  }
}

# ---------- Scaling rule: keep average CPU near the target ----------
resource "aws_autoscaling_policy" "cpu" {
  name                      = "food-web-cpu-target"
  autoscaling_group_name    = aws_autoscaling_group.web.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target
  }
}

# ---------- Optional nightly scale to zero (off by default) ----------
resource "aws_autoscaling_schedule" "night_off" {
  count = var.enable_schedules ? 1 : 0

  scheduled_action_name  = "night-off"
  autoscaling_group_name = aws_autoscaling_group.web.name
  recurrence             = "0 23 * * *"
  time_zone              = "Asia/Kolkata"
  min_size               = 0
  max_size               = var.web_max_size
  desired_capacity       = 0
}

resource "aws_autoscaling_schedule" "morning_on" {
  count = var.enable_schedules ? 1 : 0

  scheduled_action_name  = "morning-on"
  autoscaling_group_name = aws_autoscaling_group.web.name
  recurrence             = "0 9 * * *"
  time_zone              = "Asia/Kolkata"
  min_size               = var.web_day_size
  max_size               = var.web_max_size
  desired_capacity       = var.web_day_size
}

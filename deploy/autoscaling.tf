resource "aws_autoscaling_group" "linux" {
  name = local.e3s_linux_autoscaling_name
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.e3s_linux.id
        version            = aws_launch_template.e3s_linux.latest_version
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          weighted_capacity = override.value.weight
          instance_type     = override.value.instance_type
        }
      }
    }

    instances_distribution {
      // as of now, there is no support of usual if/else blocks
      // if var.linux_linux_spot_price == 0 use only on-demand instances, else will be used only on-spot
      on_demand_percentage_above_base_capacity = var.spot_price.linux == "" ? 100 : 0
      spot_max_price                           = var.spot_price.linux
      spot_allocation_strategy                 = "capacity-optimized-prioritized"
      on_demand_allocation_strategy            = "prioritized"
    }
  }

  desired_capacity_type = "units"
  desired_capacity      = 1
  min_size              = 1
  max_size              = 50

  default_cooldown = 10

  health_check_type         = "EC2"
  health_check_grace_period = 10

  vpc_zone_identifier = [var.private_subnet_1_id, var.private_subnet_2_id]

  termination_policies  = ["AllocationStrategy"]
  protect_from_scale_in = true

  force_delete            = true
  service_linked_role_arn = format("arn:aws:iam::%s:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", data.aws_caller_identity.current.account_id)

  dynamic "tag" {
    for_each = local.e3s_common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  # ECS adds this when the ASG joins a capacity provider; undeclared means Terraform removes it.
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity, min_size, max_size]
  }
}

resource "aws_autoscaling_group" "windows" {
  name = local.e3s_windows_autoscaling_name
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.e3s_windows.id
        version            = aws_launch_template.e3s_windows.latest_version
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          weighted_capacity = override.value.weight
          instance_type     = override.value.instance_type
        }
      }
    }

    instances_distribution {
      // as of now, there is no support of usual if/else blocks
      // if var.windows_spot_price == 0 use only on-demand instances, else will be used only on-spot
      on_demand_percentage_above_base_capacity = var.spot_price.windows == "" ? 100 : 0
      spot_max_price                           = var.spot_price.windows
      spot_allocation_strategy                 = "capacity-optimized-prioritized"
      on_demand_allocation_strategy            = "prioritized"
    }
  }

  desired_capacity = 0
  min_size         = 0
  max_size         = 50

  default_cooldown = 10

  health_check_type         = "EC2"
  health_check_grace_period = 10

  vpc_zone_identifier = [var.private_subnet_1_id, var.private_subnet_2_id]

  termination_policies  = ["AllocationStrategy"]
  protect_from_scale_in = true

  force_delete            = true
  service_linked_role_arn = format("arn:aws:iam::%s:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", data.aws_caller_identity.current.account_id)

  tag {
    key                 = "Name"
    propagate_at_launch = false
    value               = local.e3s_agent_instance_name
  }

  dynamic "tag" {
    for_each = local.e3s_common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity, min_size, max_size]
  }
}

resource "aws_autoscaling_policy" "linux_forecast" {
  autoscaling_group_name = aws_autoscaling_group.linux.name
  name                   = "predictive"
  policy_type            = "PredictiveScaling"
  predictive_scaling_configuration {
    metric_specification {
      target_value = 100
      predefined_metric_pair_specification {
        predefined_metric_type = "ASGCPUUtilization"
      }
    }
    mode                         = "ForecastAndScale"
    scheduling_buffer_time       = "120"
    max_capacity_breach_behavior = "HonorMaxCapacity"
  }

  lifecycle {
    ignore_changes = [predictive_scaling_configuration]
  }
}

resource "aws_autoscaling_policy" "windows_forecast" {
  autoscaling_group_name = aws_autoscaling_group.windows.name
  name                   = "predictive"
  policy_type            = "PredictiveScaling"
  predictive_scaling_configuration {
    metric_specification {
      target_value = 100
      predefined_metric_pair_specification {
        predefined_metric_type = "ASGCPUUtilization"
      }
    }
    mode                         = "ForecastAndScale"
    scheduling_buffer_time       = "300"
    max_capacity_breach_behavior = "HonorMaxCapacity"
  }

  lifecycle {
    ignore_changes = [predictive_scaling_configuration]
  }
}

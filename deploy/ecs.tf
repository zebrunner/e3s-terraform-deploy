resource "aws_ecs_capacity_provider" "e3s_linux" {
  name = local.e3s_linux_capacityprovider
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.linux.arn
    managed_termination_protection = "DISABLED"
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 100
      instance_warmup_period    = 300
    }
  }
}

resource "aws_ecs_capacity_provider" "e3s_windows" {
  name = local.e3s_windows_capacityprovider
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.windows.arn
    managed_termination_protection = "DISABLED"
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 100
      instance_warmup_period    = 300
    }
  }
}

resource "aws_ecs_cluster" "e3s" {
  name = local.e3s_cluster_name
}

resource "aws_ecs_cluster_capacity_providers" "attachment" {
  cluster_name       = aws_ecs_cluster.e3s.name
  capacity_providers = [aws_ecs_capacity_provider.e3s_linux.name, aws_ecs_capacity_provider.e3s_windows.name]
  default_capacity_provider_strategy {
    weight            = 1
    capacity_provider = aws_ecs_capacity_provider.e3s_linux.name
  }

  provisioner "local-exec" {
    command = <<-EOF
ecsPolicy=`aws ecs describe-clusters --region ${var.region} --cluster ${aws_ecs_cluster.e3s.name} --include ATTACHMENTS --query 'clusters[0].attachments[].details[]' | grep "${aws_ecs_capacity_provider.e3s_windows.name}" -A 4 | grep "ECSManagedAutoScalingPolicy" | cut -d ':' -f 2 | cut -d '"' -f 2`
aws autoscaling put-scaling-policy --region ${var.region} --auto-scaling-group-name ${aws_autoscaling_group.windows.name} --policy-name "$ecsPolicy" --policy-type TargetTrackingScaling --target-tracking-configuration "{ \"CustomizedMetricSpecification\": { \"MetricName\": \"CapacityProviderReservation\", \"Namespace\": \"AWS/ECS/ManagedScaling\", \"Dimensions\": [{ \"Name\": \"CapacityProviderName\", \"Value\": \"${aws_ecs_capacity_provider.e3s_windows.name}\" }, { \"Name\": \"ClusterName\", \"Value\": \"${aws_ecs_cluster.e3s.name}\"}], \"Statistic\": \"Average\"}, \"TargetValue\": 100.0, \"DisableScaleIn\": false }" --no-enabled
EOF
  }

  provisioner "local-exec" {
    command = <<-EOF
ecsPolicy2=`aws ecs describe-clusters --region ${var.region} --cluster ${aws_ecs_cluster.e3s.name} --include ATTACHMENTS --query 'clusters[0].attachments[].details[]' | grep "${aws_ecs_capacity_provider.e3s_linux.name}" -A 4 | grep "ECSManagedAutoScalingPolicy" | cut -d ':' -f 2 | cut -d '"' -f 2`
aws autoscaling put-scaling-policy --region ${var.region} --auto-scaling-group-name ${aws_autoscaling_group.linux.name} --policy-name "$ecsPolicy2" --policy-type TargetTrackingScaling --target-tracking-configuration "{ \"CustomizedMetricSpecification\": { \"MetricName\": \"CapacityProviderReservation\", \"Namespace\": \"AWS/ECS/ManagedScaling\", \"Dimensions\": [{ \"Name\": \"CapacityProviderName\", \"Value\": \"${aws_ecs_capacity_provider.e3s_linux.name}\" }, { \"Name\": \"ClusterName\", \"Value\": \"${aws_ecs_cluster.e3s.name}\"}], \"Statistic\": \"Average\"}, \"TargetValue\": 100.0, \"DisableScaleIn\": false }" --no-enabled
EOF
  }
}

resource "aws_ecs_task_definition" "linux_node_exporter" {
  count                    = var.asg_instance_metrics ? 1 : 0
  family                   = "exporters"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.e3s_exporter[0].arn
  network_mode             = "host"

  volume {
    name      = "proc"
    host_path = "/proc"
  }

  volume {
    name      = "sys"
    host_path = "/sys"
  }

  volume {
    name      = "root"
    host_path = "/"
  }

  volume {
    name      = "cgroup"
    host_path = "/cgroup"
  }

  volume {
    name      = "var_run"
    host_path = "/var/run"
  }

  volume {
    name      = "var_lib_docker"
    host_path = "/var/lib/docker"
  }

  volume {
    name      = "dev_disk"
    host_path = "/dev/disk"
  }

  # port 9100 
  container_definitions = jsonencode([
    {
      name              = "cadvisor-exporter"
      image             = "gcr.io/cadvisor/cadvisor"
      essential         = true
      cpu               = 128
      memory            = 256
      memoryReservation = 256
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 9101
          protocol      = "tcp"
        }
      ],
      mountPoints = [
        {
          sourceVolume  = "root"
          containerPath = "/rootfs"
          readOnly      = true
        },
        {
          sourceVolume  = "cgroup"
          containerPath = "/cgroup"
          readOnly      = true
        },
        {
          sourceVolume  = "var_run"
          containerPath = "/var/run"
          readOnly      = true
        },
        {
          sourceVolume  = "var_lib_docker"
          containerPath = "/var/lib/docker"
          readOnly      = true
        },
        {
          sourceVolume  = "dev_disk"
          containerPath = "/dev/disk"
          readOnly      = true
        },
        {
          sourceVolume  = "cgroup"
          containerPath = "/sys/fs/cgroup"
          readOnly      = true
        }
      ],
      privileged             = true,
      readonlyRootFilesystem = false
    },
    {
      name              = "node-exporter"
      image             = "public.ecr.aws/zebrunner/node-exporter:v1.8.2"
      essential         = true
      cpu               = 128
      memory            = 256
      memoryReservation = 256
      pidMode           = "host"
      privileged        = true
      mountPoints = [
        {
          sourceVolume  = "proc"
          containerPath = "/host/proc"
          readOnly      = true
        },
        {
          sourceVolume  = "sys"
          containerPath = "/host/sys"
          readOnly      = true
        },
        {
          sourceVolume  = "root"
          containerPath = "/rootfs"
          readOnly      = true
        }
      ]
      command = [
        "--path.procfs=/host/proc",
        "--path.rootfs=/rootfs",
        "--path.sysfs=/host/sys",
        "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
      ]
    }
  ])
}

# resource "aws_ecs_task_definition" "linux_exporter" {
#   count                    = var.asg_instance_metrics ? 1 : 0
#   family                   = "exporters"
#   requires_compatibilities = ["EC2"]
#   task_role_arn            = aws_iam_role.e3s_exporter[0].arn

#   volume {
#     name      = "root"
#     host_path = "/"
#   }

#   volume {
#     name      = "cgroup"
#     host_path = "/cgroup"
#   }

#   volume {
#     name      = "var_run"
#     host_path = "/var/run"
#   }

#   volume {
#     name      = "var_lib_docker"
#     host_path = "/var/lib/docker"
#   }

#   volume {
#     name      = "dev_disk"
#     host_path = "/dev/disk"
#   }

#   container_definitions = jsonencode([
#     {
#       name              = "cadvisor-exporter"
#       image             = "gcr.io/cadvisor/cadvisor"
#       essential         = true
#       cpu               = 128
#       memory            = 256
#       memoryReservation = 256
#       portMappings = [
#         {
#           containerPort = 8080
#           hostPort      = 9101
#           protocol      = "tcp"
#         }
#       ],
#       mountPoints = [
#         {
#           sourceVolume  = "root"
#           containerPath = "/rootfs"
#           readOnly      = true
#         },
#         {
#           sourceVolume  = "cgroup"
#           containerPath = "/cgroup"
#           readOnly      = true
#         },
#         {
#           sourceVolume  = "var_run"
#           containerPath = "/var/run"
#           readOnly      = true
#         },
#         {
#           sourceVolume  = "var_lib_docker"
#           containerPath = "/var/lib/docker"
#           readOnly      = true
#         },
#         {
#           sourceVolume  = "dev_disk"
#           containerPath = "/dev/disk"
#           readOnly      = true
#         },
#         {
#           sourceVolume  = "cgroup"
#           containerPath = "/sys/fs/cgroup"
#           readOnly      = true
#         }
#       ],
#       privileged             = true,
#       readonlyRootFilesystem = false
#     }
#   ])
# }

resource "aws_ecs_service" "linux_exporter" {
  count               = length(aws_ecs_task_definition.linux_exporter) > 0 ? 1 : 0
  name                = "linux-exporter"
  cluster             = aws_ecs_cluster.e3s.name
  task_definition     = aws_ecs_task_definition.linux_exporter[0].arn
  launch_type         = "EC2"
  scheduling_strategy = "DAEMON"
  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.os-type == linux"
  }
}

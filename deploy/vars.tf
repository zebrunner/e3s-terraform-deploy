# TODO: Add custom condition for vars
# Mandatory
variable "environment" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}

variable "e3s_key_name" {
  type     = string
  nullable = false
}

variable "bucket" {
  type = object({
    exists = bool
    name   = string
    region = string
  })
  nullable = false
}

# Optional
variable "allow_agent_ssh" {
  type    = bool
  default = false
}

variable "cert" {
  type    = string
  default = ""
}

variable "enable_cloudwatch" {
  type    = bool
  default = false
}

variable "e3s_server_instance_type" {
  type    = string
  default = "m5n.large"
}

variable "data_layer_remote" {
  type    = bool
  default = true
}

variable "asg_instance_metrics" {
  type    = bool
  default = false
}

variable "nat" {
  type    = bool
  default = false
}

variable "max_az_number" {
  type    = number
  default = 3
}

variable "profile" {
  type    = string
  default = ""
}

variable "remote_db" {
  type = object({
    username = string
    pass     = string
  })
  default = {
    username = "postgres"
    pass     = "postgres"
  }
}

variable "instance_types" {
  type = list(object({
    weight        = number
    instance_type = string
  }))
  default = [
    {
      weight        = 1
      instance_type = "c5a.4xlarge"
    },
    {
      weight        = 2
      instance_type = "c5a.8xlarge"
    }
  ]
}

variable "spot_price" {
  type = object({
    linux   = string
    windows = string
  })
  default = {
    linux   = ""
    windows = ""
  }
}

variable "zebrunner" {
  type = object({
    host = string
    user = string
    pass = string
  })
  default = {
    host = ""
    user = ""
    pass = ""
  }
}

# consts
locals {
  service_name = "e3s"

  e3s_server_instance_name = join("-", [local.service_name, var.environment])

  e3s_agent_key_name = join("-", [local.service_name, var.environment, "agent"])

  e3s_policy_name        = join("-", [local.service_name, var.environment, "policy"])
  e3s_role_name          = join("-", [local.service_name, var.environment, "role"])
  e3s_agent_policy_name  = join("-", [local.service_name, var.environment, "agent", "policy"])
  e3s_agent_role_name    = join("-", [local.service_name, var.environment, "agent", "role"])
  e3s_task_policy_name   = join("-", [local.service_name, var.environment, "task", "policy"])
  e3s_task_role_name     = join("-", [local.service_name, var.environment, "task", "role"])
  e3s_exporter_role_name = join("-", [local.service_name, var.environment, "exporter", "role"])

  e3s_server_sg_name              = join("-", [local.service_name, var.environment, "sg"])
  e3s_agent_sg_name               = join("-", [local.service_name, var.environment, "agent", "sg"])
  e3s_rdp_sg_name                 = join("-", [local.service_name, var.environment, "rdp", "sg"])
  e3s_rds_sg_name                 = join("-", [local.service_name, var.environment, "rds", "sg"])
  e3s_cache_sg_name               = join("-", [local.service_name, var.environment, "cache", "sg"])
  e3s_cloudwatch_endpoint_sg_name = join("-", [local.service_name, var.environment, "cloudwatch", "sg"])

  e3s_cluster_name                 = join("-", [local.service_name, var.environment])
  e3s_linux_launch_template_name   = join("-", [local.service_name, var.environment, "linux", "launch", "template"])
  e3s_windows_launch_template_name = join("-", [local.service_name, var.environment, "windows", "launch", "template"])
  e3s_linux_autoscaling_name       = join("-", [local.service_name, var.environment, "linux", "asg"])
  e3s_windows_autoscaling_name     = join("-", [local.service_name, var.environment, "windows", "asg"])
  e3s_linux_capacityprovider       = join("-", [local.service_name, var.environment, "linux", "capacityprovider"])
  e3s_windows_capacityprovider     = join("-", [local.service_name, var.environment, "windows", "capacityprovider"])
  e3s_tg_name                      = join("-", [local.service_name, var.environment, "tg"])
  e3s_alb_name                     = join("-", [local.service_name, var.environment, "alb"])
  e3s_listener_name                = join("-", [local.service_name, var.environment, "listener"])
  e3s_log_group_name               = join("-", [local.service_name, var.environment, "log-group"])

  e3s_rds_subnet_name       = join("-", [local.service_name, var.environment, "rds", "subnet"])
  e3s_rds_db_name           = join("-", [local.service_name, var.environment, "postgres"])
  e3s_serverless_cache_name = join("-", [local.service_name, var.environment, "redis"])
}

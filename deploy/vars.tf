# Mandatory
variable "resources_prefix" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}

variable "s3_bucket" {
  type = object({
    exists = bool
    name   = string
    region = string
  })
  nullable = false
}

variable "vpc_id" {
  type     = string
  nullable = false
}
variable "vpc_cidr_block" {
  type     = string
  nullable = false
}

variable "lacework_secret_name" {
  type     = string
  nullable = false
  default  = "lacework/access-token"
}

# Optional
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

locals {
  e3s_server_instance_name = join("-", [var.resources_prefix, "server"])
  e3s_agent_instance_name = join("-", [var.resources_prefix, "agent"])
  e3s_agent_key_pair_name  = join("-", [var.resources_prefix, "agent"])

  e3s_policy_name       = join("-", [var.resources_prefix, "server", "policy"])
  e3s_role_name         = join("-", [var.resources_prefix, "server", "role"])
  e3s_agent_policy_name = join("-", [var.resources_prefix, "agent", "policy"])
  e3s_agent_role_name   = join("-", [var.resources_prefix, "agent", "role"])
  e3s_task_policy_name  = join("-", [var.resources_prefix, "task", "policy"])
  e3s_task_role_name    = join("-", [var.resources_prefix, "task", "role"])

  e3s_server_sg_name              = join("-", [var.resources_prefix, "server", "sg"])
  e3s_agent_sg_name               = join("-", [var.resources_prefix, "agent", "sg"])
  e3s_rdp_sg_name                 = join("-", [var.resources_prefix, "rdp", "sg"])
  e3s_rds_sg_name                 = join("-", [var.resources_prefix, "rds", "sg"])
  e3s_cache_sg_name               = join("-", [var.resources_prefix, "cache", "sg"])
  e3s_cloudwatch_endpoint_sg_name = join("-", [var.resources_prefix, "cloudwatch", "sg"])

  e3s_cluster_name                 = join("-", [var.resources_prefix, "cluster"])
  e3s_linux_launch_template_name   = join("-", [var.resources_prefix, "linux", "launch", "template"])
  e3s_windows_launch_template_name = join("-", [var.resources_prefix, "windows", "launch", "template"])
  e3s_linux_autoscaling_name       = join("-", [var.resources_prefix, "linux", "asg"])
  e3s_windows_autoscaling_name     = join("-", [var.resources_prefix, "windows", "asg"])
  e3s_linux_capacityprovider       = join("-", [var.resources_prefix, "linux", "capacityprovider"])
  e3s_windows_capacityprovider     = join("-", [var.resources_prefix, "windows", "capacityprovider"])
  e3s_tg_name                      = join("-", [var.resources_prefix, "tg"])
  e3s_alb_name                     = join("-", [var.resources_prefix, "alb"])
  e3s_listener_name                = join("-", [var.resources_prefix, "listener"])
  e3s_log_group_name               = join("-", [var.resources_prefix, "log-group"])

  e3s_rds_subnet_name       = join("-", [var.resources_prefix, "rds", "subnet"])
  e3s_rds_db_name           = join("-", [var.resources_prefix, "postgres"])
  e3s_serverless_cache_name = join("-", [var.resources_prefix, "redis"])
}

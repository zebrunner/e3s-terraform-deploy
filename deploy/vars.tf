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
variable "public_subnet_1_id" {
  type     = string
  nullable = false
}
variable "public_subnet_2_id" {
  type     = string
  nullable = false
}
variable "private_subnet_1_id" {
  type     = string
  nullable = false
}
variable "private_subnet_2_id" {
  type     = string
  nullable = false
}

variable "lacework_secret_name" {
  type     = string
  nullable = false
  default  = "e3s/lacework/access-token"
}

variable "allowed_e3s_server_cidr_blocks" {
  type        = list(string)
  description = "List of IPv4 CIDR blocks allowed to access the application (ALB and router ports). Maximum 165 CIDR blocks (55 per security group, 3 security groups total)"
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.allowed_e3s_server_cidr_blocks) <= 165
    error_message = "Maximum 165 CIDR blocks (55 per security group, 3 security groups total)"
  }
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

########################################################################################################################

variable "automatic_update_enabled" {
  type    = bool
  default = false
}

variable "automatic_update_cron" {
  type    = string
  default = "cron(0 12 ? * SAT *)"
}

variable "automatic_update_github_repo" {
  type    = string
  default = "https://github.com/zebrunner/e3s-terraform-deploy.git"
}

variable "automatic_update_github_branch" {
  type    = string
  default = "existing-nats-and-lacework"
}

variable "automatic_update_github_credentials_secret_name" {
  type    = string
  default = "e3s/automatic-update/github-token"
}

variable "automatic_update_terraform_tfvars_secret_name" {
  type    = string
  default = "e3s/automatic-update/terraform.tfvars"
}

variable "automatic_update_config_s3_tfbackend_secret_name" {
  type    = string
  default = "e3s/automatic-update/config.s3.tfbackend"
}

variable "automatic_update_policy_1_arn" {
  type    = string
  default = ""
}

variable "automatic_update_policy_2_arn" {
  type    = string
  default = ""
}

variable "automatic_update_policy_3_arn" {
  type    = string
  default = ""
}

# SNS Configuration
########################################################################################################################

variable "sns_topic_secret_name" {
  type        = string
  description = "Name of the AWS Secrets Manager secret containing SNS topic ARNs (SUCCESS_SNS_TOPIC_ARN and FAILURE_SNS_TOPIC_ARN)"
  default     = "esg/automatic-update/sns-topics"
}

variable "success_sns_topic_name" {
  type        = string
  description = "Name of the SNS topic for successful build notifications"
  default     = "build-success"
}

variable "failure_sns_topic_name" {
  type        = string
  description = "Name of the SNS topic for failed build notifications"
  default     = "build-failure"
}

variable "success_notification_emails" {
  type        = list(string)
  description = "List of email addresses to subscribe to success notifications"
  default     = []

  validation {
    condition     = alltrue([for email in var.success_notification_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))])
    error_message = "All email addresses must be valid email format."
  }
}

variable "failure_notification_emails" {
  type        = list(string)
  description = "List of email addresses to subscribe to failure notifications"
  default     = []

  validation {
    condition     = alltrue([for email in var.failure_notification_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))])
    error_message = "All email addresses must be valid email format."
  }
}

########################################################################################################################

locals {
  e3s_server_instance_name = join("-", [var.resources_prefix, "server"])
  e3s_agent_instance_name  = join("-", [var.resources_prefix, "agent"])

  e3s_server_role_name       = join("-", [var.resources_prefix, "server", "role"])
  e3s_agent_role_name        = join("-", [var.resources_prefix, "agent", "role"])
  e3s_task_role_name         = join("-", [var.resources_prefix, "task", "role"])
  e3s_codebuild_role_name    = join("-", [var.resources_prefix, "codebuild", "role"])
  e3s_event_bridge_role_name = join("-", [var.resources_prefix, "event", "bridge", "role"])

  e3s_server_policy_name       = join("-", [var.resources_prefix, "server", "policy"])
  e3s_agent_policy_name        = join("-", [var.resources_prefix, "agent", "policy"])
  e3s_task_policy_name         = join("-", [var.resources_prefix, "task", "policy"])
  e3s_codebuild_policy_name    = join("-", [var.resources_prefix, "codebuild", "policy"])
  e3s_event_bridge_policy_name = join("-", [var.resources_prefix, "event", "bridge", "policy"])

  e3s_server_sg_name              = join("-", [var.resources_prefix, "server", "sg"])
  e3s_agent_sg_name               = join("-", [var.resources_prefix, "agent", "sg"])
  e3s_rdp_sg_name                 = join("-", [var.resources_prefix, "rdp", "sg"])
  e3s_rds_sg_name                 = join("-", [var.resources_prefix, "rds", "sg"])
  e3s_cache_sg_name               = join("-", [var.resources_prefix, "cache", "sg"])
  e3s_codebuild_sg_name           = join("-", [var.resources_prefix, "codebuild", "sg"])
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

  e3s_codebuild_project_name = join("-", [var.resources_prefix, "automatic", "update"])
  e3s_event_bridge_rule_name = join("-", [var.resources_prefix, "automatic", "update"])
}

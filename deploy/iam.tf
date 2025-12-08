data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  count = var.automatic_update_enabled ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "event_bridge_assume_role_policy" {
  count = var.automatic_update_enabled ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

########################################################################################################################

resource "aws_iam_role" "e3s_server" {
  name               = local.e3s_server_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

resource "aws_iam_role_policy" "e3s_server" {
  name   = local.e3s_server_policy_name
  role   = aws_iam_role.e3s_server.id
  policy = templatefile("./iam_data/server-policy.json", {
    bucket_name          = var.s3_bucket.name
    env                  = var.resources_prefix
    account              = data.aws_caller_identity.current.account_id
    region               = var.region
    lacework_secret_name = var.lacework_secret_name
  })
}

resource "aws_iam_role_policy_attachment" "e3s_server_ssm" {
  role       = aws_iam_role.e3s_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "e3s_server" {
  name = local.e3s_server_role_name
  role = aws_iam_role.e3s_server.name
}

########################################################################################################################

resource "aws_iam_role" "e3s_agent" {
  name               = local.e3s_agent_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

resource "aws_iam_role_policy" "e3s_agent" {
  name   = local.e3s_agent_policy_name
  role   = aws_iam_role.e3s_agent.id
  policy = templatefile("./iam_data/agent-policy.json", {
    env                  = var.resources_prefix
    account              = data.aws_caller_identity.current.account_id
    region               = var.region
    lacework_secret_name = var.lacework_secret_name
  })
}

resource "aws_iam_role_policy_attachment" "e3s_agent_ssm" {
  role       = aws_iam_role.e3s_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "e3s_agent" {
  name = local.e3s_agent_role_name
  role = aws_iam_role.e3s_agent.name
}

########################################################################################################################

resource "aws_iam_role" "e3s_task" {
  name               = local.e3s_task_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role_policy" "e3s_task" {
  name   = local.e3s_task_policy_name
  role   = aws_iam_role.e3s_task.id
  policy = templatefile("./iam_data/task-policy.json", {
    bucket_name = var.s3_bucket.name
  })
}

########################################################################################################################

resource "aws_iam_role" "codebuild" {
  count              = var.automatic_update_enabled ? 1 : 0
  name               = local.e3s_codebuild_role_name
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy[0].json
}

resource "aws_iam_role_policy" "codebuild" {
  count  = var.automatic_update_enabled ? 1 : 0
  name   = local.e3s_codebuild_policy_name
  role   = aws_iam_role.codebuild[0].id
  policy = templatefile(
    "./iam_data/codebuild-policy.json",
    {
      account                       = data.aws_caller_identity.current.account_id
      region                        = var.region
      config_s3_tfbackend_secret_id = var.automatic_update_config_s3_tfbackend_secret_name
      terraform_tfvars_secret_id    = var.automatic_update_terraform_tfvars_secret_name
      codebuild_project_name        = local.e3s_codebuild_project_name
    }
  )
}

resource "aws_iam_role_policy" "codebuild_sns_management" {
  count  = var.automatic_update_enabled ? 1 : 0
  name   = "${local.e3s_codebuild_policy_name}-sns-management"
  role   = aws_iam_role.codebuild[0].id
  policy = templatefile(
    "./iam_data/codebuild-sns-management-policy.json",
    {
      account                              = data.aws_caller_identity.current.account_id
      region                               = var.region
      notification_sns_topic_secret_name   = var.notification_sns_topic_secret_name
      notification_sns_topic_success       = var.notification_sns_topic_success
      notification_sns_topic_failure       = var.notification_sns_topic_failure
    }
  )
}

resource "aws_iam_role_policy_attachment" "codebuild_extra_policy_1" {
  count      = var.automatic_update_enabled ? 1 : 0
  role       = aws_iam_role.codebuild[0].id
  policy_arn = var.automatic_update_policy_1_arn
}

resource "aws_iam_role_policy_attachment" "codebuild_extra_policy_2" {
  count      = var.automatic_update_enabled ? 1 : 0
  role       = aws_iam_role.codebuild[0].id
  policy_arn = var.automatic_update_policy_2_arn
}

resource "aws_iam_role_policy_attachment" "codebuild_extra_policy_3" {
  count      = var.automatic_update_enabled ? 1 : 0
  role       = aws_iam_role.codebuild[0].id
  policy_arn = var.automatic_update_policy_3_arn
}

########################################################################################################################

resource "aws_iam_role" "event_bridge" {
  count              = var.automatic_update_enabled ? 1 : 0
  name               = local.e3s_event_bridge_role_name
  assume_role_policy = data.aws_iam_policy_document.event_bridge_assume_role_policy[0].json
}

resource "aws_iam_role_policy" "event_bridge" {
  count  = var.automatic_update_enabled ? 1 : 0
  name   = local.e3s_event_bridge_policy_name
  role   = aws_iam_role.event_bridge[0].id
  policy = templatefile(
    "./iam_data/event-bridge-policy.json",
    {
      account                = data.aws_caller_identity.current.account_id
      region                 = var.region
      codebuild_project_name = local.e3s_codebuild_project_name
    }
  )
}

resource "local_file" "ami_info" {
  filename = "${path.module}/ami_info.txt"
  content = jsonencode({
    esg_server_ami_id      = data.aws_ami.ubuntu_22_04.id
    esg_server_ami_name    = data.aws_ami.ubuntu_22_04.name
    esg_server_ami_date    = data.aws_ami.ubuntu_22_04.creation_date
    esg_worker_node_ami_id       = data.aws_ami.zbr_linux.id
    esg_worker_node_ami_name     = data.aws_ami.zbr_linux.name
    esg_worker_node_ami_date     = data.aws_ami.zbr_linux.creation_date
  })
}

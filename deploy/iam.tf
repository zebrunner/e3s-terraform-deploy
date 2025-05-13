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

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

########################################################################################################################

resource "aws_iam_policy" "e3s" {
  name   = local.e3s_policy_name
  policy = templatefile("./iam_data/e3s-server-policy.json", {
    bucket_name          = var.s3_bucket.name
    env                  = var.resources_prefix
    account              = data.aws_caller_identity.current.account_id
    region               = var.region
    lacework_secret_name = var.lacework_secret_name
  })
}

resource "aws_iam_policy" "e3s_agent" {
  name   = local.e3s_agent_policy_name
  policy = templatefile("./iam_data/e3s-agent-policy.json", {
    env                  = var.resources_prefix
    account              = data.aws_caller_identity.current.account_id
    region               = var.region
    lacework_secret_name = var.lacework_secret_name
  })
}

resource "aws_iam_policy" "e3s_task" {
  name   = local.e3s_task_policy_name
  policy = templatefile("./iam_data/e3s-task-policy.json", {
    bucket_name = var.s3_bucket.name
  })
}

########################################################################################################################

resource "aws_iam_role" "e3s_task" {
  name                = local.e3s_task_role_name
  assume_role_policy  = data.aws_iam_policy_document.ecs_assume_role_policy.json
}

resource "aws_iam_role" "e3s" {
  name                = local.e3s_role_name
  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role" "e3s_agent" {
  name                = local.e3s_agent_role_name
  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
}

########################################################################################################################

resource "aws_iam_role_policy_attachment" "e3s_task" {
  role       = aws_iam_role.e3s_task.name
  policy_arn = aws_iam_policy.e3s_task.arn
}

resource "aws_iam_role_policy_attachment" "e3s" {
  role       = aws_iam_role.e3s.name
  policy_arn = aws_iam_policy.e3s.arn
}

resource "aws_iam_role_policy_attachment" "e3s_ssm" {
  role       = aws_iam_role.e3s.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "e3s_agent" {
  role       = aws_iam_role.e3s_agent.name
  policy_arn = aws_iam_policy.e3s_agent.arn
}

resource "aws_iam_role_policy_attachment" "e3s_agent_ssm" {
  role       = aws_iam_role.e3s_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

########################################################################################################################

resource "aws_iam_instance_profile" "e3s" {
  name = local.e3s_role_name
  role = aws_iam_role.e3s.name
}

resource "aws_iam_instance_profile" "e3s_agent" {
  name = local.e3s_agent_role_name
  role = aws_iam_role.e3s_agent.name
}

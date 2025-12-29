# SNS Topics for Build Notifications
########################################################################################################################

resource "terraform_data" "always_run" {
  count = var.automatic_update_enabled ? 1 : 0
  
  input = timestamp()
}

resource "time_sleep" "wait_25_seconds" {
  count = var.automatic_update_enabled ? 1 : 0
  
  depends_on = [
    aws_iam_role_policy.codebuild_sns_management
  ]
  
  create_duration = "25s"
  
  lifecycle {
    replace_triggered_by = [terraform_data.always_run]
  }
}

resource "aws_sns_topic" "success" {
  count = var.automatic_update_enabled ? 1 : 0
  name  = var.notification_sns_topic_success

  tags = {
    Name        = var.notification_sns_topic_success
    Purpose     = "CodeBuild Success Notifications"
  }

  depends_on = [
    time_sleep.wait_25_seconds
  ]
}

resource "aws_sns_topic" "failure" {
  count = var.automatic_update_enabled ? 1 : 0
  name  = var.notification_sns_topic_failure

  tags = {
    Name        = var.notification_sns_topic_failure
    Purpose     = "CodeBuild Failure Notifications"
  }

  depends_on = [
    time_sleep.wait_25_seconds
  ]
}

# Email Subscriptions for Success Topic
########################################################################################################################

resource "aws_sns_topic_subscription" "success_emails" {
  count     = var.automatic_update_enabled ? length(var.notification_email_success) : 0
  topic_arn = aws_sns_topic.success[0].arn
  protocol  = "email"
  endpoint  = var.notification_email_success[count.index]
  depends_on = [
    time_sleep.wait_25_seconds
  ]
}

# Email Subscriptions for Failure Topic
########################################################################################################################

resource "aws_sns_topic_subscription" "failure_emails" {
  count     = var.automatic_update_enabled ? length(var.notification_email_failure) : 0
  topic_arn = aws_sns_topic.failure[0].arn
  protocol  = "email"
  endpoint  = var.notification_email_failure[count.index]
  depends_on = [
    time_sleep.wait_25_seconds
  ]
}

# Secrets Manager Secret with SNS Topic ARNs
########################################################################################################################

resource "aws_secretsmanager_secret" "sns_topics" {
  count       = var.automatic_update_enabled ? 1 : 0
  name        = var.notification_sns_topic_secret_name
  description = "SNS Topic ARNs for CodeBuild success and failure notifications"

  tags = {
    Name        = var.notification_sns_topic_secret_name
    Purpose     = "CodeBuild Notifications"
  }

  depends_on = [
    time_sleep.wait_25_seconds
  ]
}

resource "aws_secretsmanager_secret_version" "sns_topics" {
  count     = var.automatic_update_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.sns_topics[0].id
  secret_string = jsonencode({
    SUCCESS_SNS_TOPIC_ARN = aws_sns_topic.success[0].arn
    FAILURE_SNS_TOPIC_ARN = aws_sns_topic.failure[0].arn
  })
  depends_on = [
    time_sleep.wait_25_seconds
  ]
}

# Local File with AMI Information
########################################################################################################################

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

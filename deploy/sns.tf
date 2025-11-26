# SNS Topics for Build Notifications
########################################################################################################################

resource "aws_sns_topic" "success" {
  count = var.automatic_update_enabled ? 1 : 0
  name  = var.success_sns_topic_name

  tags = {
    Name        = var.success_sns_topic_name
    Environment = "test-migration"
    Purpose     = "CodeBuild Success Notifications"
  }
}

resource "aws_sns_topic" "failure" {
  count = var.automatic_update_enabled ? 1 : 0
  name  = var.failure_sns_topic_name

  tags = {
    Name        = var.failure_sns_topic_name
    Environment = "test-migration"
    Purpose     = "CodeBuild Failure Notifications"
  }
}

# Email Subscriptions for Success Topic
########################################################################################################################

resource "aws_sns_topic_subscription" "success_emails" {
  count     = var.automatic_update_enabled ? length(var.success_notification_emails) : 0
  topic_arn = aws_sns_topic.success[0].arn
  protocol  = "email"
  endpoint  = var.success_notification_emails[count.index]
}

# Email Subscriptions for Failure Topic
########################################################################################################################

resource "aws_sns_topic_subscription" "failure_emails" {
  count     = var.automatic_update_enabled ? length(var.failure_notification_emails) : 0
  topic_arn = aws_sns_topic.failure[0].arn
  protocol  = "email"
  endpoint  = var.failure_notification_emails[count.index]
}

# Secrets Manager Secret with SNS Topic ARNs
########################################################################################################################

resource "aws_secretsmanager_secret" "sns_topics" {
  count       = var.automatic_update_enabled ? 1 : 0
  name        = var.sns_topic_secret_name
  description = "SNS Topic ARNs for CodeBuild success and failure notifications"

  tags = {
    Name        = var.sns_topic_secret_name
    Environment = "test-migration"
    Purpose     = "CodeBuild Notifications"
  }
}

resource "aws_secretsmanager_secret_version" "sns_topics" {
  count     = var.automatic_update_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.sns_topics[0].id
  secret_string = jsonencode({
    SUCCESS_SNS_TOPIC_ARN = aws_sns_topic.success[0].arn
    FAILURE_SNS_TOPIC_ARN = aws_sns_topic.failure[0].arn
  })
}

resource "aws_cloudwatch_event_rule" "automatic_update" {
  count = var.automatic_update_enabled ? 1 : 0
  name = local.e3s_event_bridge_rule_name
  # every weekday at 09:00 UTC
  schedule_expression = var.automatic_update_cron
  # └─ minute (0)
  #    └─ hour (9)
  #       └─ day-of-month (?)
  #          └─ month (*)
  #             └─ day-of-week (MON-FRI)
  #                └─ year (*)
}

resource "aws_cloudwatch_event_target" "build_target" {
  count = var.automatic_update_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.automatic_update[0].name
  target_id = "TriggerCodeBuild"
  arn       = aws_codebuild_project.automatic_update[0].arn
  role_arn  = aws_iam_role.event_bridge[0].arn
}

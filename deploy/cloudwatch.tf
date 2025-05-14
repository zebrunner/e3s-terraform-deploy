resource "aws_vpc_endpoint" "cloudwatch" {
  count = var.enable_cloudwatch ? 1 : 0

  vpc_id     = var.vpc_id
  subnet_ids = [var.private_subnet_1_id, var.private_subnet_2_id]

  service_name       = format("com.amazonaws.%s.logs", var.region)
  vpc_endpoint_type  = "Interface"
  policy             = file("./iam_data/cloudwatch-endpoint-policy.json")
  security_group_ids = [aws_security_group.cloudwatch[0].id]

  private_dns_enabled = true
}

resource "aws_cloudwatch_log_group" "e3s_tasks" {
  count             = var.enable_cloudwatch ? 1 : 0
  name              = local.e3s_log_group_name
  log_group_class   = "STANDARD"
  retention_in_days = 3
}

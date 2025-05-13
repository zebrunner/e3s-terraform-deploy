data "aws_subnets" "cloudwatch" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]
  }
}

########################################################################################################################

resource "aws_vpc_endpoint" "cloudwatch" {
  count = var.enable_cloudwatch ? 1 : 0

  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.cloudwatch.ids

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

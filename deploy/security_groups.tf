locals {
  cidr_blocks_chunks = chunklist(var.allowed_e3s_server_cidr_blocks, 55)
  cidr_blocks_sg     = try(local.cidr_blocks_chunks[0], [])
  cidr_blocks_sg2    = try(local.cidr_blocks_chunks[1], [])
  cidr_blocks_sg3    = try(local.cidr_blocks_chunks[2], [])
}

resource "aws_security_group" "e3s_server" {
  vpc_id = var.vpc_id
  name   = local.e3s_server_sg_name
}

resource "aws_vpc_security_group_ingress_rule" "e3s_server_alb" {
  for_each = toset(local.cidr_blocks_sg)

  security_group_id = aws_security_group.e3s_server.id
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  from_port         = var.cert == "" ? 80 : 443
  to_port           = var.cert == "" ? 80 : 443
  description       = "Allow HTTP/HTTPS from allowed IP"
}

resource "aws_vpc_security_group_ingress_rule" "e3s_server_router_ports_from_alb" {
  security_group_id            = aws_security_group.e3s_server.id
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.e3s_server.id
  from_port                    = 4444
  to_port                      = 4445
  description                  = "Allow router ports from ALB (same security group)"
}

resource "aws_vpc_security_group_egress_rule" "e3s_server_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.e3s_server.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "e3s_server_outbound_traffic_ipv6" {
  security_group_id = aws_security_group.e3s_server.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

# Security Group 2
resource "aws_security_group" "e3s_server_2" {
  vpc_id = var.vpc_id
  name   = "${local.e3s_server_sg_name}-2"
}

resource "aws_vpc_security_group_ingress_rule" "e3s_server_2_alb" {
  for_each = toset(local.cidr_blocks_sg2)

  security_group_id = aws_security_group.e3s_server_2.id
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  from_port         = var.cert == "" ? 80 : 443
  to_port           = var.cert == "" ? 80 : 443
  description       = "Allow HTTP/HTTPS from allowed IP"
}

resource "aws_vpc_security_group_egress_rule" "e3s_server_2_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.e3s_server_2.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "e3s_server_2_outbound_traffic_ipv6" {
  security_group_id = aws_security_group.e3s_server_2.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

# Security Group 3
resource "aws_security_group" "e3s_server_3" {
  vpc_id = var.vpc_id
  name   = "${local.e3s_server_sg_name}-3"
}

resource "aws_vpc_security_group_ingress_rule" "e3s_server_3_alb" {
  for_each = toset(local.cidr_blocks_sg3)

  security_group_id = aws_security_group.e3s_server_3.id
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
  from_port         = var.cert == "" ? 80 : 443
  to_port           = var.cert == "" ? 80 : 443
  description       = "Allow HTTP/HTTPS from allowed IP"
}

resource "aws_vpc_security_group_egress_rule" "e3s_server_3_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.e3s_server_3.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "e3s_server_3_outbound_traffic_ipv6" {
  security_group_id = aws_security_group.e3s_server_3.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

########################################################################################################################

resource "aws_security_group" "e3s_agent" {
  vpc_id = var.vpc_id
  name   = local.e3s_agent_sg_name
}

resource "aws_vpc_security_group_ingress_rule" "e3s_agent_inbound_traffic" {
  security_group_id = aws_security_group.e3s_agent.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "${aws_instance.e3s_server.private_ip}/32"
  description       = "docker port range to access from e3s server"
  from_port         = 32768
  to_port           = 64536
}

resource "aws_vpc_security_group_egress_rule" "e3s_agent_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.e3s_agent.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "e3s_agent_outbound_traffic_ipv6" {
  security_group_id = aws_security_group.e3s_agent.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

########################################################################################################################

resource "aws_security_group" "rds" {
  vpc_id = var.vpc_id
  name   = local.e3s_rds_sg_name
}

resource "aws_vpc_security_group_egress_rule" "e3s_rds_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "e3s_rds_outbound_traffic_ipv6" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_ingress_rule" "e3s_rds_ipv4" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "${aws_instance.e3s_server.private_ip}/32"
  from_port         = 5432
  to_port           = 5432
}

########################################################################################################################

resource "aws_security_group" "redis" {
  vpc_id = var.vpc_id
  name   = local.e3s_cache_sg_name
}

resource "aws_vpc_security_group_egress_rule" "e3s_redis_outbound_traffic_ipv4" {
  security_group_id = aws_security_group.redis.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "e3s_redis_outbound_traffic_ipv6" {
  security_group_id = aws_security_group.redis.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_ingress_rule" "e3s_redis_ipv4" {
  security_group_id = aws_security_group.redis.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "${aws_instance.e3s_server.private_ip}/32"
  from_port         = 6379
  to_port           = 6380
}

########################################################################################################################

resource "aws_security_group" "cloudwatch" {
  count  = var.enable_cloudwatch ? 1 : 0
  vpc_id = var.vpc_id
  name   = local.e3s_cloudwatch_endpoint_sg_name
}

resource "aws_vpc_security_group_ingress_rule" "cloudwatch" {
  count                        = var.enable_cloudwatch ? 1 : 0
  security_group_id            = aws_security_group.cloudwatch[0].id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.e3s_agent.id
}

resource "aws_vpc_security_group_egress_rule" "cloudwatch_outbound_traffic_ipv4" {
  count             = var.enable_cloudwatch ? 1 : 0
  security_group_id = aws_security_group.cloudwatch[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "cloudwatch_outbound_traffic_ipv6" {
  count             = var.enable_cloudwatch ? 1 : 0
  security_group_id = aws_security_group.cloudwatch[0].id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

########################################################################################################################

resource "aws_security_group" "codebuild" {
  count  = var.automatic_update_enabled ? 1 : 0
  vpc_id = var.vpc_id
  name   = local.e3s_codebuild_sg_name
}

resource "aws_vpc_security_group_egress_rule" "codebuild_outbound_traffic_ipv4" {
  count             = var.automatic_update_enabled ? 1 : 0
  security_group_id = aws_security_group.codebuild[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "codebuild_outbound_traffic_ipv6" {
  count             = var.automatic_update_enabled ? 1 : 0
  security_group_id = aws_security_group.codebuild[0].id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

# Migration block
########################################################################################################################

moved {
  from = aws_vpc_security_group_ingress_rule.e3s_server_alb
  to   = aws_vpc_security_group_ingress_rule.e3s_server_alb["0.0.0.0/0"]
}

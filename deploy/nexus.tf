# Internal Nexus Repository OSS that proxies and caches Maven Central.
# Endpoint is private (internal ALB, HTTP). Artifact blobs are stored in S3.

data "aws_ami" "ubuntu_24_04" {
  most_recent = true

  # Canonical
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_s3_bucket" "nexus" {
  count         = var.nexus_enabled && !var.nexus_s3_bucket.exists ? 1 : 0
  bucket        = var.nexus_s3_bucket.name
  force_destroy = true

  tags = {
    "data-classification" = local.e3s_data_tags["data-classification"]
  }

  depends_on = [aws_vpc_endpoint.s3_gateway]
}

resource "aws_s3_bucket_public_access_block" "nexus" {
  count                   = var.nexus_enabled && !var.nexus_s3_bucket.exists ? 1 : 0
  bucket                  = aws_s3_bucket.nexus[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################################################################################################################
# IAM: instance role with S3 blob-store access and SSM

resource "aws_iam_role" "nexus" {
  count              = local.nexus_count
  name               = local.e3s_nexus_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

resource "aws_iam_role_policy" "nexus" {
  count = local.nexus_count
  name  = local.e3s_nexus_policy_name
  role  = aws_iam_role.nexus[0].id
  policy = templatefile("./iam_data/nexus-server-policy.json", {
    bucket_name = var.nexus_s3_bucket.name
  })
}

resource "aws_iam_role_policy_attachment" "nexus_ssm" {
  count      = local.nexus_count
  role       = aws_iam_role.nexus[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nexus" {
  count = local.nexus_count
  name  = local.e3s_nexus_role_name
  role  = aws_iam_role.nexus[0].name
}

########################################################################################################################
# Security groups

resource "aws_security_group" "nexus_alb" {
  count  = local.nexus_count
  vpc_id = var.vpc_id
  name   = local.e3s_nexus_alb_sg_name
}

resource "aws_vpc_security_group_ingress_rule" "nexus_alb_http" {
  count             = local.nexus_count
  security_group_id = aws_security_group.nexus_alb[0].id
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 80
  to_port           = 80
  description       = "Allow HTTP from inside the VPC only"
}

resource "aws_vpc_security_group_egress_rule" "nexus_alb_outbound_ipv4" {
  count             = local.nexus_count
  security_group_id = aws_security_group.nexus_alb[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "nexus" {
  count  = local.nexus_count
  vpc_id = var.vpc_id
  name   = local.e3s_nexus_sg_name
}

resource "aws_vpc_security_group_ingress_rule" "nexus_from_alb" {
  count                        = local.nexus_count
  security_group_id            = aws_security_group.nexus[0].id
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.nexus_alb[0].id
  from_port                    = 8081
  to_port                      = 8081
  description                  = "Allow Nexus port only from the internal ALB"
}

resource "aws_vpc_security_group_egress_rule" "nexus_outbound_ipv4" {
  count             = local.nexus_count
  security_group_id = aws_security_group.nexus[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "nexus_outbound_ipv6" {
  count             = local.nexus_count
  security_group_id = aws_security_group.nexus[0].id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

########################################################################################################################
# Internal ALB (Option 2: raw ELB DNS name, HTTP only, no internet exposure)

resource "aws_lb" "nexus" {
  count              = local.nexus_count
  name               = local.e3s_nexus_alb_name
  internal           = true
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  subnets            = [var.private_subnet_1_id, var.private_subnet_2_id]
  security_groups    = [aws_security_group.nexus_alb[0].id]
  idle_timeout       = 300
}

resource "aws_lb_target_group" "nexus" {
  count            = local.nexus_count
  name             = local.e3s_nexus_tg_name
  vpc_id           = var.vpc_id
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  port             = 8081
  target_type      = "instance"

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    enabled             = true
    path                = "/service/rest/v1/status"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = 200
  }

  deregistration_delay = 60
}

resource "aws_lb_target_group_attachment" "nexus" {
  count            = local.nexus_count
  target_group_arn = aws_lb_target_group.nexus[0].arn
  target_id        = aws_instance.nexus[0].id
  port             = 8081
}

resource "aws_lb_listener" "nexus" {
  count             = local.nexus_count
  load_balancer_arn = aws_lb.nexus[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexus[0].arn
  }
}

########################################################################################################################
# Nexus host

resource "aws_instance" "nexus" {
  count                  = local.nexus_count
  ami                    = data.aws_ami.ubuntu_24_04.id
  instance_type          = var.nexus_instance_type
  iam_instance_profile   = aws_iam_instance_profile.nexus[0].name
  vpc_security_group_ids = [aws_security_group.nexus[0].id]
  subnet_id              = var.private_subnet_1_id

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = local.e3s_nexus_instance_name
  }

  volume_tags = merge(local.e3s_volume_tags, { Name = local.e3s_nexus_instance_name })

  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = var.nexus_root_volume_size
  }

  user_data = templatefile("./ec2_data/nexus_user_data.sh", {
    region           = var.region
    nexus_image      = var.nexus_image
    nexus_bucket     = var.nexus_s3_bucket.name
    maven_remote_url = var.nexus_maven_central_url
    admin_password   = var.nexus_admin_password
  })

  user_data_replace_on_change = true

  depends_on = [aws_s3_bucket.nexus]
}

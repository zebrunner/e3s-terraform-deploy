data "aws_ami" "ubuntu_22_04" {
  most_recent = true

  # Amazon
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
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

########################################################################################################################

resource "aws_instance" "e3s_server" {
  ami                  = data.aws_ami.ubuntu_22_04.id
  instance_type        = var.e3s_server_instance_type
  iam_instance_profile = aws_iam_instance_profile.e3s_server.name

  vpc_security_group_ids = [aws_security_group.e3s_server.id, aws_security_group.e3s_server_1.id, aws_security_group.e3s_server_2.id]
  subnet_id              = var.private_subnet_1_id

  cpu_options {
    core_count       = 1
    threads_per_core = 2
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = local.e3s_server_instance_name
  }

  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = 100
  }

  user_data = templatefile("./ec2_data/e3s_user_data.sh", {
    region                   = var.region
    cluster_name             = local.e3s_cluster_name
    task_role                = local.e3s_task_role_name
    env                      = var.resources_prefix
    lacework_secret_name     = var.lacework_secret_name
    linux_capacityprovider   = local.e3s_linux_capacityprovider
    windows_capacityprovider = local.e3s_windows_capacityprovider
    target_group             = local.e3s_tg_name
    bucket_name              = var.s3_bucket.name
    bucket_region            = length(aws_s3_bucket.main) > 0 ? var.region : var.s3_bucket.region
    log_group                = length(aws_cloudwatch_log_group.e3s_tasks) > 0 ? local.e3s_log_group_name : ""

    nat = true

    zbr_host = var.zebrunner.host
    zbr_user = var.zebrunner.user
    zbr_pass = var.zebrunner.pass

    # db_dns      = aws_rds_cluster.aurora.endpoint
    remote_data   = true
    db_username   = var.remote_db.username
    db_pass       = var.remote_db.pass
    db_name       = aws_db_instance.postgres.db_name
    db_dns        = aws_db_instance.postgres.endpoint
    cache_address = aws_elasticache_serverless_cache.redis.endpoint[0].address
    cache_port    = aws_elasticache_serverless_cache.redis.endpoint[0].port
  })

  depends_on = [aws_ecs_cluster.e3s, aws_lb_listener.main]

  lifecycle {
    ignore_changes = [user_data]
  }
}

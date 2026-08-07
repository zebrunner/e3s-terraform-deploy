data "aws_rds_engine_version" "postgres" {
  engine       = "postgres"
  version      = "13"
  default_only = true
}

########################################################################################################################

resource "aws_db_subnet_group" "rds" {
  name        = local.e3s_rds_subnet_name
  description = "RDS subnet group"
  subnet_ids  = [var.private_subnet_1_id, var.private_subnet_2_id]
}

resource "aws_db_instance" "postgres" {
  identifier                 = local.e3s_rds_db_name
  db_name                    = "postgres"
  allocated_storage          = 10
  max_allocated_storage      = 30
  instance_class             = "db.t4g.small"
  engine                     = "postgres"
  engine_version             = data.aws_rds_engine_version.postgres.version
  username                   = var.remote_db.username
  password                   = var.remote_db.pass
  auto_minor_version_upgrade = true
  db_subnet_group_name       = aws_db_subnet_group.rds.name
  port                       = 5432

  maintenance_window      = "Mon:00:00-Mon:01:00"
  backup_window           = "01:01-02:00"
  backup_retention_period = 2
  storage_encrypted       = true

  deletion_protection      = false
  apply_immediately        = false
  skip_final_snapshot      = true
  delete_automated_backups = true

  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    "data-classification" = local.e3s_data_tags["data-classification"]
  }
}

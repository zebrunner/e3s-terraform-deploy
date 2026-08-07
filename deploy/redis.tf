resource "aws_elasticache_serverless_cache" "redis" {
  name                 = local.e3s_serverless_cache_name
  engine               = "redis"
  major_engine_version = "7"

  cache_usage_limits {
    data_storage {
      maximum = 5
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = 5000
    }
  }

  subnet_ids         = [var.private_subnet_1_id, var.private_subnet_2_id]
  security_group_ids = [aws_security_group.redis.id]

  tags = {
    "data-classification" = local.e3s_data_tags["data-classification"]
  }
}

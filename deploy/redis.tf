data "aws_subnets" "redis" {
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

  subnet_ids         = data.aws_subnets.redis.ids
  security_group_ids = [aws_security_group.redis.id]
}

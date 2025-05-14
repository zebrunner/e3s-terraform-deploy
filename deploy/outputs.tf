output "e3s_ip" {
  description = "public address of e3s server"
  value       = aws_instance.e3s_server.public_ip
}

output "lb_dns" {
  description = "load balancer dns"
  value       = aws_lb.main.dns_name
}

output "db_dns" {
  description = "postgres dns"
  value       = aws_db_instance.postgres.endpoint
}

output "cache_address" {
  description = "redis read/write host:port"
  value       = format(
    "%s:%s",
    aws_elasticache_serverless_cache.redis.endpoint[0].address,
    aws_elasticache_serverless_cache.redis.endpoint[0].port
  )
}

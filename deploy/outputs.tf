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

output "cloudwatch_vpc_endpoint_id" {
  description = "vpc interface endpoint for cloudwatch logs upload"
  value       = (length(aws_vpc_endpoint.cloudwatch) != 0
    ? aws_vpc_endpoint.cloudwatch[0].id
    : "cloudwatch endpoint is not created"
  )
}

output "s3_vpc_gw_endpoint_id" {
  description = "vpc gateway endpoint for s3 artifacts upload"
  value       = aws_vpc_endpoint.s3_gateway.id
}

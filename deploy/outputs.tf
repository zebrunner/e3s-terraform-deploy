output "lb_dns" {
  description = "load balancer dns"
  value       = aws_lb.main.dns_name
}

output "nexus_alb_dns" {
  description = "Internal Nexus ALB DNS name (reachable only inside the VPC)"
  value       = var.nexus_enabled ? aws_lb.nexus[0].dns_name : null
}

output "nexus_url" {
  description = "Internal Maven cache URL. Use it as the internal-cache repository URL in pom.xml"
  value       = var.nexus_enabled ? "http://${aws_lb.nexus[0].dns_name}/repository/maven-public/" : null
}

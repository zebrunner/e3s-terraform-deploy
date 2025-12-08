output "lb_dns" {
  description = "load balancer dns"
  value       = aws_lb.main.dns_name
}

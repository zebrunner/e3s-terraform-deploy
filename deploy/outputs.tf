output "lb_dns" {
  description = "load balancer dns"
  value       = aws_lb.main.dns_name
}

resource "local_file" "ami_info" {
  filename = "${path.module}/ami_info.txt"
  content = jsonencode({
    esg_server_ami_id      = data.aws_ami.ubuntu_22_04.id
    esg_server_ami_name    = data.aws_ami.ubuntu_22_04.name
    esg_server_ami_date    = data.aws_ami.ubuntu_22_04.creation_date
    esg_worker_node_ami_id       = data.aws_ami.zbr_linux.id
    esg_worker_node_ami_name     = data.aws_ami.zbr_linux.name
    esg_worker_node_ami_date     = data.aws_ami.zbr_linux.creation_date
  })
}

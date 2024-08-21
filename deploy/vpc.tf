resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "internet" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(sort(data.aws_availability_zones.available.names), 0, length(data.aws_availability_zones.available.names) > var.max_az_number ? var.max_az_number : length(data.aws_availability_zones.available.names))
  az_subnets = { for id, az_name in local.azs : az_name => { "public_cidr" : cidrsubnet(aws_vpc.main.cidr_block, 8, id), "private_cidr" : cidrsubnet(aws_vpc.main.cidr_block, 8, length(local.azs) + id) } }
  az_eips = zipmap(local.azs, aws_eip.static_ip)
}

resource "aws_subnet" "public_per_zone" {
  for_each = local.az_subnets

  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone       = each.key
  cidr_block              = each.value["public_cidr"]
}

resource "aws_subnet" "private_per_zone" {
  for_each = var.nat ? local.az_subnets : tomap({})

  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false
  availability_zone       = each.key
  cidr_block              = each.value["private_cidr"]
}

resource "aws_route_table_association" "public-subnets-internet-associations" {
  for_each       = aws_subnet.public_per_zone
  route_table_id = aws_route_table.internet.id
  subnet_id      = aws_subnet.public_per_zone[each.key].id
}

resource "aws_eip" "static_ip" {
  count                = var.nat ? length(local.az_subnets) : 0
  domain               = "vpc"
  network_border_group = var.region
}

resource "aws_nat_gateway" "nat-gws" {
  for_each      = var.nat ? aws_subnet.public_per_zone: tomap({})
  subnet_id     = aws_subnet.public_per_zone[each.key].id
  allocation_id = local.az_eips[each.key].id
  depends_on = [aws_internet_gateway.igw, aws_eip.static_ip]
}

resource "aws_route_table" "internet_private" {
  for_each = aws_nat_gateway.nat-gws
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gws[each.key].id
  }
}

resource "aws_route_table_association" "nat-associations" {
  for_each = aws_subnet.private_per_zone
  route_table_id = aws_route_table.internet_private[each.key].id
  subnet_id      = aws_subnet.private_per_zone[each.key].id
}

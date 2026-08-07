# data "aws_vpc_endpoint" "s3_gateway" {
#   vpc_id       = var.vpc_id
#   service_name = format("com.amazonaws.%s.s3", var.region)
# }

data "aws_subnets" "s3" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]
  }
}

data "aws_route_tables" "s3" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "association.subnet-id"
    values = data.aws_subnets.s3.ids
  }
}

########################################################################################################################

resource "aws_s3_bucket" "main" {
  count         = var.s3_bucket.exists ? 0 : 1
  bucket        = var.s3_bucket.name
  force_destroy = true

  tags = {
    "data-classification" = local.e3s_data_tags["data-classification"]
  }
}

# Existing buckets (s3_bucket.exists = true) are not managed by aws_s3_bucket above.
# aws_s3_bucket_tagging replaces the bucket's tag set entirely.
resource "aws_s3_bucket_tagging" "existing_assets" {
  count  = var.s3_bucket.exists ? 1 : 0
  bucket = var.s3_bucket.name

  tags = local.e3s_data_tags
}

resource "aws_s3_bucket_policy" "vpc_restrict_policy" {
  count  = var.s3_bucket.exists ? 0 : 1
  bucket = var.s3_bucket.name
  policy = templatefile("./iam_data/s3-bucket-policy.json", {
    bucket_name     = var.s3_bucket.name
    vpc_endpoint_id = aws_vpc_endpoint.s3_gateway.id
  })
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id = var.vpc_id

  route_table_ids   = data.aws_route_tables.s3.ids
  service_name      = format("com.amazonaws.%s.s3", var.region)
  vpc_endpoint_type = "Gateway"
  policy = templatefile("./iam_data/s3-endpoint-policy.json", {
    bucket_name = var.s3_bucket.name
    region      = var.region
  })
}

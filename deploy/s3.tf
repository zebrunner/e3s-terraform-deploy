resource "aws_s3_bucket" "main" {
  count         = var.bucket.exists ? 0 : 1
  bucket        = var.bucket.name
  force_destroy = true
}

resource "aws_s3_bucket_policy" "vpc_restrict_policy" {
  count  = var.bucket.exists || length(aws_vpc_endpoint.s3_gw) == 0 ? 0 : 1
  bucket = var.bucket.name
  policy = templatefile("./iam_data/s3-bucket-policy.json", {
    bucket_name     = var.bucket.name
    vpc_endpoint_id = aws_vpc_endpoint.s3_gw[0].id
  })
}

resource "aws_vpc_endpoint" "s3_gw" {
  count = var.nat ? 1 : 0

  vpc_id = aws_vpc.main.id

  route_table_ids   = [for route-table in aws_route_table.internet_private : route-table.id]
  service_name      = format("com.amazonaws.%s.s3", var.region)
  vpc_endpoint_type = "Gateway"
  policy = templatefile("./iam_data/s3-endpoint-policy.json", {
    bucket_name = var.bucket.name
    region      = var.region
  })
}

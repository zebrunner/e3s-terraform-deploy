data "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = var.vpc_id
  service_name = format("com.amazonaws.%s.s3", var.region)
}

########################################################################################################################

resource "aws_s3_bucket" "main" {
  count         = var.s3_bucket.exists ? 0 : 1
  bucket        = var.s3_bucket.name
  force_destroy = true
}

resource "aws_s3_bucket_policy" "vpc_restrict_policy" {
  count  = var.s3_bucket.exists ? 0 : 1
  bucket = var.s3_bucket.name
  policy = templatefile("./iam_data/s3-bucket-policy.json", {
    bucket_name     = var.s3_bucket.name
    vpc_endpoint_id = data.aws_vpc_endpoint.s3_gateway.id
  })
}

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
    bucket_name       = var.s3_bucket.name
    state_bucket_name = var.terraform_state_bucket
    region            = var.region
  })

  lifecycle {
    precondition {
      condition     = !var.automatic_update_enabled || var.terraform_state_bucket != ""
      error_message = "terraform_state_bucket must be set to the bucket from config.s3.tfbackend when automatic_update_enabled is true, otherwise terraform init fails inside CodeBuild."
    }
  }
}

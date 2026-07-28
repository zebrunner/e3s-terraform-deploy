terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }

  backend "s3" {}

  required_version = "~> 1.12.0"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = local.e3s_common_tags
  }
}

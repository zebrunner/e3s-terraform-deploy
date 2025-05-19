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
  region  = var.region
  default_tags {
    tags = {
      Environment = var.resources_prefix
      Application = "e3s"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }

  backend "s3" {}

  required_version = "~> 1.10.0"
}

provider "aws" {
  region  = var.region
  profile = var.profile
  default_tags {
    tags = {
      Environment = var.environment
      Name        = local.service_name
    }
  }
}

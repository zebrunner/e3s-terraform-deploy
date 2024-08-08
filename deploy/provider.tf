terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }

  backend "s3" {}

  required_version = "~> 1.9.4"
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

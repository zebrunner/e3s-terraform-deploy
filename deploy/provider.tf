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

  backend "s3" {
    bucket = var.terraform_remote_state.bucket
    key    = var.terraform_remote_state.key
    region = var.terraform_remote_state.region
  }

  required_version = "~> 1.8.5"
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

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

locals {
  az_count = 3
  vpc_cidr = var.vpc_cidr
}

module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = local.vpc_cidr
  subnets_cidrs = [
    [for i in range(local.az_count) : cidrsubnet(local.vpc_cidr, 3, i)],
    [for i in range(local.az_count) : cidrsubnet(local.vpc_cidr, 3, i + 4)],
  ]
  subnets_public = [true, true] # use public subnet to save money. (nat does charge)
  vpc_tags = {
    Name       = "main"
    Maintainer = "Ray"
  }
}

module "sg" {
  source      = "./modules/sg"
  name        = "public-80-443"
  description = "a usage demo"

  tags = {
    Name = "pub-80-443"
  }

  rules = {
    "allow_ping" = {
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "http_public" = {
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    },
    "https_public" = {
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  depends_on = [
    module.vpc
  ]
}

module "bastion" {
  source       = "./modules/bastion"
  cidr_sources = ["1.2.3.4/32"]

  depends_on = [
    module.vpc
  ]
}

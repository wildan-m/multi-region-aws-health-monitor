terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Environment = var.environment
      Region      = var.region
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

locals {
  availability_zones = ["${var.region}a", "${var.region}c"]
}

module "vpc" {
  source = "../../modules/vpc"

  project_name            = var.project_name
  environment            = var.environment
  vpc_cidr               = var.vpc_cidr
  availability_zones     = local.availability_zones
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  tags                   = var.tags
}

module "compute" {
  source = "../../modules/compute"

  project_name        = var.project_name
  environment        = var.environment
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_type      = var.instance_type
  monitoring_enabled = var.monitoring_enabled
  tags               = var.tags
}

module "database" {
  source = "../../modules/database"

  project_name           = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  web_security_group_id = module.compute.security_group_id
  db_instance_class     = var.db_instance_class
  monitoring_enabled    = var.monitoring_enabled
  tags                  = var.tags
}
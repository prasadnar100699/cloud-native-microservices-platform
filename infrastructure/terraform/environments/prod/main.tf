provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source             = "../../modules/vpc"
  environment        = var.environment
  project_name       = var.project_name
  owner              = var.owner
  vpc_cidr           = "10.20.0.0/16" # Distinct corporate network partition
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

module "eks" {
  source          = "../../modules/eks"
  environment     = var.environment
  project_name    = var.project_name
  owner           = var.owner
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  instance_types  = ["m5.large"] # Production-grade compute (General Purpose optimized)
}
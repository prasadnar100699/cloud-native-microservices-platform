provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source             = "../../modules/vpc"
  environment        = var.environment
  project_name       = var.project_name
  owner              = var.owner
  vpc_cidr           = "10.10.0.0/16" # Completely non-overlapping CIDR block for isolation
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

module "eks" {
  source          = "../../modules/eks"
  environment     = var.environment
  project_name    = var.project_name
  owner           = var.owner
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  instance_types  = ["t3.large"] # Slightly beefier instances for pre-prod integration testing
}
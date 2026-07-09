provider "aws" {
  region = var.aws_region
}

# 1. Orchestrate the Network Module
module "vpc" {
  source             = "../../modules/vpc"
  environment        = var.environment
  project_name       = var.project_name
  owner              = var.owner
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# 2. Orchestrate the Compute Module (Dependent on VPC Outputs)
module "eks" {
  source          = "../../modules/eks"
  environment     = var.environment
  project_name    = var.project_name
  owner           = var.owner
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  instance_types  = ["t3.medium"]
}
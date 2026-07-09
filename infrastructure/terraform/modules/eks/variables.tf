variable "environment" {
  type        = string
  description = "Deployment environment name (dev, qa, prod)"
}

variable "project_name" {
  type        = string
  description = "The name of the project infrastructure belongs to"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where EKS cluster will be deployed"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for worker node placement"
}

variable "owner" {
  type        = string
  description = "Engineering or DevSecOps team responsible for this cluster"
}

variable "instance_types" {
  type        = list(string)
  description = "EC2 Instance types for managed node groups"
  default     = ["t3.medium"]
}
variable "environment" {
  type        = string
  description = "Deployment environment name (e.g., dev, qa, prod)"
}

variable "project_name" {
  type        = string
  description = "The name of the project infrastructure belongs to"
  default     = "enterprise-cloud-platform"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC network"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of target availability zones for high-availability multi-AZ layout"
}

variable "owner" {
  type        = string
  description = "Engineering or DevSecOps team responsible for this infrastructure"
  default     = "devsecops-platform-team"
}
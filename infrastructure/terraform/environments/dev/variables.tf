variable "aws_region" {
  type        = string
  description = "Target AWS Region for deployment"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Logical deployment stage"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Application suite root name"
  default     = "enterprise-platform"
}

variable "owner" {
  type        = string
  description = "Engineering or DevSecOps team responsible for this infrastructure"
  default     = "devsecops-platform-team"
}
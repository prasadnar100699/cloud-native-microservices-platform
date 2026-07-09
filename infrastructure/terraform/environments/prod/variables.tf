variable "aws_region" {
  type        = string
  description = "Target AWS Region for production"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Logical deployment stage"
  default     = "prod"
}

variable "project_name" {
  type        = string
  description = "Application suite root name"
  default     = "enterprise-platform"
}

variable "owner" {
  type        = string
  description = "Engineering or DevSecOps team responsible for production"
  default     = "devsecops-platform-team"
}
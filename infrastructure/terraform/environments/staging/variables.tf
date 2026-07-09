variable "aws_region" {
  type        = string
  description = "Target AWS Region for staging"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Logical deployment stage"
  default     = "staging"
}

variable "project_name" {
  type        = string
  description = "Application suite root name"
  default     = "enterprise-platform"
}

variable "owner" {
  type        = string
  description = "Engineering or DevSecOps team responsible for staging"
  default     = "devsecops-platform-team"
}
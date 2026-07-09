output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Root ID of the target VPC network"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the provisioned EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The internal API server endpoint URL"
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC Provider ARN to bind to Kubernetes ServiceAccounts"
}
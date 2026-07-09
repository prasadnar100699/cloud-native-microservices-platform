output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Production VPC ID"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the production EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The production API server endpoint URL"
}
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Staging VPC ID"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the staging EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The staging API server endpoint URL"
}
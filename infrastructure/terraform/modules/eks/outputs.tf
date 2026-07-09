output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "The name of the provisioned EKS Cluster"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "The private API endpoint for the EKS control plane"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.this.certificate_authority[0].data
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.eks.arn
  description = "The ARN of the OIDC Provider for mapping IAM roles to ServiceAccounts"
}

output "oidc_provider_url" {
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
  description = "The URL of the cluster's OIDC identity provider"
}
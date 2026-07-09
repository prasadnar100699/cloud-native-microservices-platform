output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the provisioned VPC infrastructure"
}

output "public_subnets" {
  value       = aws_subnet.public[*].id
  description = "List of IDs for the public subnets"
}

output "private_subnets" {
  value       = aws_subnet.private[*].id
  description = "List of IDs for the private EKS compute subnets"
}

output "data_subnets" {
  value       = aws_subnet.data[*].id
  description = "List of IDs for the isolated data subnets"
}
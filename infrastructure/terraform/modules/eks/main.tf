locals {
  common_tags = {
    Project        = var.project_name
    Environment    = var.environment
    ManagedBy      = "terraform"
    Owner          = var.owner
    SecurityReview = "approved"
    CostCenter     = "engineering-devops-01"
  }
}

# ----------------------------------------------------------------------------------------
# 1. IAM ROLE FOR EKS CONTROL PLANE
# ----------------------------------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# ----------------------------------------------------------------------------------------
# 2. KMS KEY FOR ENVELOPE ENCRYPTION OF KUBERNETES SECRETS
# ----------------------------------------------------------------------------------------
resource "aws_kms_key" "eks" {
  description             = "KMS Key for EKS Secrets Envelope Encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.common_tags
}

# ----------------------------------------------------------------------------------------
# 3. THE EKS CONTROL PLANE
# ----------------------------------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = "${var.project_name}-eks-${var.environment}"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true  # Enforces node-to-control-plane communication over private network
    endpoint_public_access  = false # DevSecOps hardening: control plane hidden from the open internet
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]

  tags = local.common_tags
}

# ----------------------------------------------------------------------------------------
# 4. IAM ROLE FOR MANAGED WORKER NODES
# ----------------------------------------------------------------------------------------
resource "aws_iam_role" "nodes" {
  name = "${var.project_name}-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

# ----------------------------------------------------------------------------------------
# 5. AWS MANAGED NODE GROUP (Compute Tier)
# ----------------------------------------------------------------------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-managed-nodes-${var.environment}"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.private_subnets

  instance_types = var.instance_types

  scaling_config {
    desired_size = 3 # 3 services minimum to handle 11 polyglot microservices smoothly
    max_size     = 5
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-worker-nodes-${var.environment}"
    }
  )
}

# ----------------------------------------------------------------------------------------
# 6. OIDC PROVIDER FOR IRSA (IAM ROLES FOR SERVICE ACCOUNTS)
# ----------------------------------------------------------------------------------------
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
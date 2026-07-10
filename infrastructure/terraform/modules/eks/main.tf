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

################################################################################
# IAM ROLE - EKS CONTROL PLANE
################################################################################

resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

################################################################################
# KMS
################################################################################

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secret encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

################################################################################
# CLOUDWATCH LOG GROUP
################################################################################

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-eks-${var.environment}/cluster"
  retention_in_days = 30

  tags = local.common_tags
}

################################################################################
# EKS CLUSTER
################################################################################

resource "aws_eks_cluster" "this" {
  name     = "${var.project_name}-eks-${var.environment}"
  role_arn = aws_iam_role.cluster.arn

  version = "1.30"

  vpc_config {
    subnet_ids = var.private_subnets

    endpoint_private_access = true

    endpoint_public_access = true

    public_access_cidrs = var.public_access_cidrs
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }

    resources = [
      "secrets"
    ]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_cloudwatch_log_group.eks,
    aws_iam_role_policy_attachment.cluster_policy
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-eks-${var.environment}"
    }
  )
}

################################################################################
# NODE IAM ROLE
################################################################################

resource "aws_iam_role" "nodes" {
  name = "${var.project_name}-${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "worker" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
# MANAGED NODE GROUP
################################################################################

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-managed-nodes-${var.environment}"

  node_role_arn = aws_iam_role.nodes.arn

  subnet_ids = var.private_subnets

  instance_types = var.instance_types

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = 3
    min_size     = 2
    max_size     = 5
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.ecr,
    aws_iam_role_policy_attachment.ssm
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-worker-nodes-${var.environment}"
    }
  )
}

################################################################################
# OIDC PROVIDER
################################################################################

data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks.certificates[0].sha1_fingerprint
  ]

  tags = local.common_tags
}
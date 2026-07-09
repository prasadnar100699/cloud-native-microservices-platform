locals {
  # Standardized Corporate Tagging Schema
  common_tags = {
    Project           = var.project_name
    Environment       = var.environment
    ManagedBy         = "terraform"
    Owner             = var.owner
    SecurityReview    = "approved"
    CostCenter        = "engineering-devops-01"
    ComplianceScope   = "pci-dss-applicable"
  }
}

# 1. Base VPC Provisioning
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc"
    }
  )
}

# 2. Public Subnet Tier (For Internet Facing ALBs/NAT Gateways)
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name                                                              = "${var.project_name}-${var.environment}-public-sub-${var.availability_zones[count.index]}"
      "kubernetes.io/role/elb"                                          = "1" # Crucial for K8s Public ALB ingress controllers
      "kubernetes.io/cluster/platform-eks-${var.environment}"           = "shared"
    }
  )
}

# 3. Private Subnet Tier (For EKS Worker Nodes & Internal Compute)
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 4) # 10.0.64.0/20, 10.0.80.0/20...
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name                                                              = "${var.project_name}-${var.environment}-private-sub-${var.availability_zones[count.index]}"
      "kubernetes.io/role/internal-elb"                                 = "1" # Crucial for K8s Internal ALB ingress controllers
      "kubernetes.io/cluster/platform-eks-${var.environment}"           = "shared"
    }
  )
}

# 4. Completely Isolated Data Subnet Tier (For Redis State Store / No Internet Routing)
resource "aws_subnet" "data" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 8) # 10.0.128.0/20, 10.0.144.0/20...
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-data-sub-${var.availability_zones[count.index]}"
    }
  )
}

# 5. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-eip"
    }
  )
}

# 6. Highly Available NAT Gateway in Public Subnet
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Placed strategically in the first public subnet

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-gw"
    }
  )
}

# 7. Route Table Configurations (Separation of Network Concerns)
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-public-rt" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-private-rt" })
}

# Data Subnets explicitly get their own route table with NO 0.0.0.0/0 routes (Absolute Isolation)
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-data-rt" })
}

# 8. Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}
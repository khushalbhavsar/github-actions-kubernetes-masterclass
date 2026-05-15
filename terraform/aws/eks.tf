data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "eks_public" {
  count = var.enable_eks ? length(var.eks_public_subnet_cidrs) : 0

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.eks_public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.project_name}-eks-public-${count.index + 1}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table_association" "eks_public" {
  count = var.enable_eks ? length(aws_subnet.eks_public) : 0

  subnet_id      = aws_subnet.eks_public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_iam_role" "eks_cluster" {
  count = var.enable_eks ? 1 : 0

  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count = var.enable_eks ? 1 : 0

  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node" {
  count = var.enable_eks ? 1 : 0

  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  count = var.enable_eks ? 1 : 0

  role       = aws_iam_role.eks_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  count = var.enable_eks ? 1 : 0

  role       = aws_iam_role.eks_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_registry" {
  count = var.enable_eks ? 1 : 0

  role       = aws_iam_role.eks_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_cluster" "this" {
  count = var.enable_eks ? 1 : 0

  name     = "${var.project_name}-eks"
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = var.eks_cluster_version

  vpc_config {
    subnet_ids              = aws_subnet.eks_public[*].id
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "${var.project_name}-eks"
  }
}

resource "aws_eks_node_group" "default" {
  count = var.enable_eks ? 1 : 0

  cluster_name    = aws_eks_cluster.this[0].name
  node_group_name = "${var.project_name}-default"
  node_role_arn   = aws_iam_role.eks_node[0].arn
  subnet_ids      = aws_subnet.eks_public[*].id
  instance_types  = var.eks_node_instance_types

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_registry
  ]

  tags = {
    Name = "${var.project_name}-eks-default-ng"
  }
}


# EKS 集群 IAM 角色
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

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
}

# 附加 EKS 集群策略到集群角色
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# 创建 EKS 集群
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]  # 添加公共访问CIDR
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}

# 节点组 IAM 角色
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

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
}

# 节点角色策略附加
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# 添加必要的 SSM 策略
resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

# 使用 AWS 官方的 EKS 优化 AMI（而不是 Ubuntu）
data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"]  # 使用 AWS 官方 AMI

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.28-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ssh 免密
resource "aws_key_pair" "eks_node_key" {
  key_name   = "eks-node-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/h331ZWQQggV5Pp78eQ18Qi3lOytWJhuGacssp5gTCmuIzmMfIW+t0fhDjWq6uda1t7NeYTh0zu5+36vkiy5s3Gr1M764X3qGKeGFmC7qe1kyF7RtVoZ4adufBgoNxtWi9zGmSBVi3G98YLhq0Tuj0mV9FT9l1F3NBOd3YbtCSWJ3Lx3WH9hMJ7eGAsBek8hatCtlDIFMQeF/xW4WBufWYkghjJE0G/Z9q4bJewrERD4B7GlDe+GGN8wAvehKKASySWgeeIwu+w6LYR7yzi+hyCCL+jyiycJ113u0gMo/oavdlFlVUeoJhmjsL46sjpgKPr2Yb0GhEVBOCW/rBXPFq+24zx/uds1PK/HtVNanr5kQBpJ4yT57hKhKhuNXWhJwuwQpzEFkwt36RqNFC/7CpH0BiRaafHDggBSnzPsNEECHnPnfgvzfcKoxMNcbbgYwZxNFEBD2Bjd11T1iS0aIxlO7RA2IMGl0Ch03lE3ztbiafRVIw6pTy09ehi7e+NE= pengchaoma@Pengchaos-MacBook-Pro.local"
}

# 创建启动模板（使用正确的引导方式）
resource "aws_launch_template" "eks_optimized" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = data.aws_ami.eks_optimized.id  # 使用 EKS 优化 AMI
  instance_type = "t3.micro"
  key_name      = aws_key_pair.eks_node_key.key_name

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  # 使用正确的 MIME 格式引导脚本
  user_data = base64encode(<<-EOT
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex

# 设置 EKS 集群信息
CLUSTER_NAME="${var.cluster_name}"
API_SERVER_URL="${aws_eks_cluster.main.endpoint}"
B64_CLUSTER_CA="${aws_eks_cluster.main.certificate_authority[0].data}"

# 使用官方的 EKS 引导脚本
/etc/eks/bootstrap.sh $CLUSTER_NAME \
  --apiserver-endpoint $API_SERVER_URL \
  --b64-cluster-ca $B64_CLUSTER_CA

--//--
EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-node"
    }
  }

  depends_on = [aws_eks_cluster.main]
}

# 创建安全组允许节点与集群通信
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.cluster_name}-nodes-"
  description = "Security group for EKS worker nodes"

  # 允许所有出站流量
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-nodes-sg"
  }

  # 使用动态块获取 VPC ID
  lifecycle {
    create_before_destroy = true
  }
}

# 获取默认 VPC
data "aws_vpc" "default" {
  default = true
}

# 创建节点组（先只创建1个进行测试）
resource "aws_eks_node_group" "nodes" {
  count = 1  # 先只创建1个节点进行测试

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "development-${count.index + 1}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

 

  # 使用启动模板
  launch_template {
    id      = aws_launch_template.eks_optimized.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  # 更新策略
  update_config {
    max_unavailable = 1
  }

  # 标签
  tags = {
    Name        = "development-${count.index + 1}"
    Environment = "development"
  }

  # 节点标签
  labels = {
    environment = "dev"
    node-type   = "managed"
  }

  # 依赖关系
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonSSMManagedInstanceCore,
    aws_eks_cluster.main,
    aws_launch_template.eks_optimized
  ]

  # 设置更长的超时时间
  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}



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

data "aws_ami" "ubuntu_eks" {
  most_recent = true
  owners      = ["099720109477"] # Canonical 的官方账号

  filter {
    name   = "name"
    values = ["ubuntu-eks/*20.04*"]  # 更通用的匹配模式
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ssh 免密
resource "aws_key_pair" "eks_node_key" {
  key_name   = "eks-node-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/h331ZWQQggV5Pp78eQ18Qi3lOytWJhuGacssp5gTCmuIzmMfIW+t0fhDjWq6uda1t7NeYTh0zu5+36vkiy5s3Gr1M764X3qGKeGFmC7qe1kyF7RtVoZ4adufBgoNxtWi9zGmSBVi3G98YLhq0Tuj0mV9FT9l1F3NBOd3YbtCSWJ3Lx3WH9hMJ7eGAsBek8hatCtlDIFMQeF/xW4WBufWYkghjJE0G/Z9q4bJewrERD4B7GlDe+GGN8wAvehKKASySWgeeIwu+w6LYR7yzi+hyCCL+jyiycJ113u0gMo/oavdlFlVUeoJhmjsL46sjpgKPr2Yb0GhEVBOCW/rBXPFq+24zx/uds1PK/HtVNanr5kQBpJ4yT57hKhKhuNXWhJwuwQpzEFkwt36RqNFC/7CpH0BiRaafHDggBSnzPsNEECHnPnfgvzfcKoxMNcbbgYwZxNFEBD2Bjd11T1iS0aIxlO7RA2IMGl0Ch03lE3ztbiafRVIw6pTy09ehi7e+NE= pengchaoma@Pengchaos-MacBook-Pro.local" # 替换为您的公钥内容
}

# 创建启动模板（用于指定 Ubuntu AMI）
resource "aws_launch_template" "ubuntu_eks" {
  name_prefix   = "${var.cluster_name}-ubuntu-"
  image_id      = data.aws_ami.ubuntu_eks.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.eks_node_key.key_name

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      volume_type = "gp3"
    }
  }

  # 用户数据 - Ubuntu 特定的引导脚本
  user_data = base64encode(<<-EOT
#!/bin/bash
set -ex
/etc/eks/bootstrap.sh ${var.cluster_name} \
  --apiserver-endpoint ${aws_eks_cluster.main.endpoint} \
  --b64-cluster-ca ${aws_eks_cluster.main.certificate_authority[0].data} \
  --container-runtime containerd
EOT
  )

  # 移除实例级别的标签，在节点组级别处理
}

# 创建多个节点组，每个都有不同的名称
resource "aws_eks_node_group" "ubuntu_nodes" {
  count = 8  # 创建8个节点组，每个对应一个实例

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "development-${count.index + 1}"  # development-1 到 development-8
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  # 使用启动模板
  launch_template {
    id      = aws_launch_template.ubuntu_eks.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 1  # 每个节点组只创建1个实例
    max_size     = 1
    min_size     = 1
  }

  # 在节点组级别添加标签
  tags = {
    Name = "development-${count.index + 1}"
  }

  # 更新策略
  update_config {
    max_unavailable = 1
  }

  # 标签
  labels = {
    os = "ubuntu"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.main
  ]
}


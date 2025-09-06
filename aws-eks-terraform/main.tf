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
    values = ["ubuntu-eks/*20.04*"]
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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/h331ZWQQggV5Pp78eQ18Qi3lOytWJhuGacssp5gTCmuIzmMfIW+t0fhDjWq6uda1t7NeYTh0zu5+36vkiy5s3Gr1M764X3qGKeGFmC7qe1kyF7RtVoZ4adufBgoNxtWi9zGmSBVi3G98YLhq0Tuj0mV9FT9l1F3NBOd3YbtCSWJ3Lx3WH9hMJ7eGAsBek8hatCtlDIFMQeF/xW4WBufWYkghjJE0G/Z9q4bJewrERD4B7GlDe+GGN8wAvehKKASySWgeeIwu+w6LYR7yzi+hyCCL+jyiycJ113u0gMo/oavdlFlVUeoJhmjsL46sjpgKPr2Yb0GhEVBOCW/rBXPFq+24zx/uds1PK/HtVNanr5kQBpJ4yT57hKhKhuNXWhJwuwQpzEFkwt36RqNFC/7CpH0BiRaafHDggBSnzPsNEECHnPnfgvzfcKoxMNcbbgYwZxNFEBD2Bjd11T1iS0aIxlO7RA2IMGl0Ch03lE3ztbiafRVIw6pTy09ehi7e+NE= pengchaoma@Pengchaos-MacBook-Pro.local"
}

# 创建启动模板（移除对集群的直接引用）
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

  # 移除对 aws_eks_cluster.main 的直接引用，避免循环依赖
  user_data = base64encode(<<-EOT
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==BOUNDARY=="

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex

# 等待 EKS 集群就绪
max_retries=30
counter=0
until curl -k https://${aws_eks_cluster.main.endpoint} --connect-timeout 5 || [ $counter -eq $max_retries ]
do
  sleep 10
  ((counter++))
done

# 安装 EKS 所需的工具
apt-get update
apt-get install -y apt-transport-https curl

# 下载并运行 EKS 引导脚本
export CLUSTER_NAME=${var.cluster_name}
export API_SERVER_URL=${aws_eks_cluster.main.endpoint}
export B64_CLUSTER_CA=${aws_eks_cluster.main.certificate_authority[0].data}
export CONTAINER_RUNTIME=containerd

# 使用官方 EKS 引导脚本
/etc/eks/bootstrap.sh $CLUSTER_NAME \
  --apiserver-endpoint $API_SERVER_URL \
  --b64-cluster-ca $B64_CLUSTER_CA \
  --container-runtime $CONTAINER_RUNTIME

--==BOUNDARY==--
EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-ubuntu-node"
    }
  }

  # 明确声明启动模板依赖于集群
  depends_on = [aws_eks_cluster.main]
}

# 创建多个节点组
resource "aws_eks_node_group" "ubuntu_nodes" {
  count = 3

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "development-${count.index + 1}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  launch_template {
    id      = aws_launch_template.ubuntu_eks.id
    version = aws_launch_template.ubuntu_eks.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  tags = {
    Name = "development-${count.index + 1}"
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    os = "ubuntu"
  }

  # 依赖关系：确保所有IAM策略已附加且集群和启动模板已创建
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.main,
    aws_launch_template.ubuntu_eks
  ]
}

# 使用 null_resource 来处理需要在节点组创建后执行的操作
resource "null_resource" "eks_node_post_creation" {
  count = 8

  triggers = {
    node_group_name = aws_eks_node_group.ubuntu_nodes[count.index].node_group_name
    cluster_endpoint = aws_eks_cluster.main.endpoint
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Node group ${self.triggers.node_group_name} created successfully"
      echo "Cluster endpoint: ${self.triggers.cluster_endpoint}"
    EOT
  }

  depends_on = [aws_eks_node_group.ubuntu_nodes]
}


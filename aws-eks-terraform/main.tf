data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ubuntu_ami = coalesce(var.ubuntu_ami_id, data.aws_ami.ubuntu.id)
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  eks_managed_node_groups = {
    ubuntu_nodes = {
      ami_type        = "CUSTOM"
      ami_id          = local.ubuntu_ami
      platform        = "ubuntu"
      instance_types  = [var.node_instance_type]
      capacity_type   = "ON_DEMAND"
      desired_size    = var.desired_size
      min_size        = var.min_size
      max_size        = var.max_size

      # Ubuntu-specific user data
      pre_bootstrap_user_data = <<-EOT
        #!/bin/bash
        set -ex
        # Install required packages for Ubuntu
        apt-get update
        apt-get install -y ca-certificates curl
        # Ensure the node can join the cluster properly
        systemctl restart containerd
      EOT

      # IAM role additional policies
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      # Tags for better resource management
      tags = {
        OS      = "Ubuntu"
        Purpose = "EKSWorkerNode"
      }
    }
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}

# Add necessary Kubernetes provider configurations
resource "kubernetes_config_map" "aws_auth" {
  depends_on = [module.eks]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = module.eks.eks_managed_node_groups["ubuntu_nodes"].iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      }
    ])
  }
}
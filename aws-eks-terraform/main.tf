# 创建单个节点组，包含多个节点
resource "aws_eks_node_group" "ubuntu_nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  ami_type       = "AL2_x86_64"  # 使用 Amazon Linux 2 EKS 优化版 AMI
  instance_types = var.instance_types
  capacity_type  = "ON_DEMAND"

  # 为每个实例设置名称标签
  labels = {
    nodegroup = "ubuntu-nodes"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_readonly,
    kubernetes_config_map.aws_auth
  ]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group"
  })
}

# 使用 null_resource 为每个 EC2 实例设置具体的名称
resource "null_resource" "tag_ec2_instances" {
  depends_on = [aws_eks_node_group.ubuntu_nodes]

  triggers = {
    cluster_name = var.cluster_name
    node_names   = join(",", var.node_instance_names)
  }

  provisioner "local-exec" {
    command = <<EOT
#!/bin/bash
sleep 60

# 获取属于EKS集群的所有实例ID
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region ${var.region} \
  --filters "Name=tag:eks:nodegroup-name,Values=${var.cluster_name}-node-group" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

echo "Found instances: $INSTANCE_IDS"

# 为每个实例设置名称标签
COUNT=1
for INSTANCE_ID in $INSTANCE_IDS; do
  if [ $COUNT -le ${length(var.node_instance_names)} ]; then
    NODE_NAME="${var.node_instance_names[COUNT-1]}"
    echo "Tagging instance $INSTANCE_ID with name: $NODE_NAME"
    
    aws ec2 create-tags \
      --region ${var.region} \
      --resources "$INSTANCE_ID" \
      --tags "Key=Name,Value=$NODE_NAME"
  else
    DEFAULT_NAME="${var.cluster_name}-node-$COUNT"
    echo "Tagging instance $INSTANCE_ID with default name: $DEFAULT_NAME"
    
    aws ec2 create-tags \
      --region ${var.region} \
      --resources "$INSTANCE_ID" \
      --tags "Key=Name,Value=$DEFAULT_NAME"
  fi
  COUNT=$((COUNT + 1))
done
EOT

    interpreter = ["bash", "-c"]
  }
}
# EKS Cluster 输出
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.cluster.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.cluster.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.cluster.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

# Node Group 输出
output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.ubuntu_nodes.id
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = aws_eks_node_group.ubuntu_nodes.arn
}

output "node_group_name" {
  description = "EKS node group name"
  value       = aws_eks_node_group.ubuntu_nodes.node_group_name
}

output "node_group_status" {
  description = "EKS node group status"
  value       = aws_eks_node_group.ubuntu_nodes.status
}

output "node_group_resources" {
  description = "EKS node group resources"
  value       = aws_eks_node_group.ubuntu_nodes.resources
}

# 如果需要以列表形式输出（即使只有一个节点组）
output "node_group_names" {
  description = "List of EKS node group names"
  value       = [aws_eks_node_group.ubuntu_nodes.node_group_name]
}

# Security Group 输出
output "node_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = aws_security_group.eks_nodes.id
}

# IAM 角色输出
output "cluster_iam_role_arn" {
  description = "IAM role ARN for EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN for EKS node group"
  value       = aws_iam_role.eks_node_group_role.arn
}

# Launch Template 输出
output "launch_template_id" {
  description = "Launch template ID for EKS nodes"
  value       = aws_launch_template.eks_node_launch_template.id
}

# AMI 输出
output "eks_optimized_ami_id" {
  description = "ID of the EKS optimized Ubuntu AMI"
  value       = data.aws_ami.eks_optimized_ubuntu.id
}
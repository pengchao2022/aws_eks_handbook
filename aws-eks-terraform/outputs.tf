output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "ubuntu_ami_id" {
  description = "Ubuntu AMI ID used for nodes"
  value       = data.aws_ami.ubuntu_eks.id
}

# 修正：使用 splat 表达式输出所有节点组的 ARN
output "node_group_arns" {
  description = "List of all node group ARNs"
  value       = aws_eks_node_group.ubuntu_nodes[*].arn
}

# 或者如果您只想输出第一个节点组的 ARN
output "first_node_group_arn" {
  description = "ARN of the first node group"
  value       = aws_eks_node_group.ubuntu_nodes[0].arn
}

output "launch_template_id" {
  description = "Launch template ID for Ubuntu nodes"
  value       = aws_launch_template.ubuntu_eks.id
}

# 添加更多有用的输出
output "node_group_names" {
  description = "List of all node group names"
  value       = aws_eks_node_group.ubuntu_nodes[*].node_group_name
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = var.cluster_name
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN for the cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN for the nodes"
  value       = aws_iam_role.node.arn
}

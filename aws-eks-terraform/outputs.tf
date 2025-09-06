# outputs.tf
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
  value       = data.aws_ami.eks_optimized.id  # 修改为正确的数据源名称
}

output "node_group_arns" {
  description = "List of all node group ARNs"
  value       = aws_eks_node_group.nodes[*].arn  # 修改为正确的资源名称
}

output "first_node_group_arn" {
  description = "ARN of the first node group"
  value       = length(aws_eks_node_group.nodes) > 0 ? aws_eks_node_group.nodes[0].arn : null  # 修改为正确的资源名称
}

output "launch_template_id" {
  description = "Launch template ID for EKS nodes"
  value       = aws_launch_template.eks_optimized.id  # 修改为正确的资源名称
}

output "node_group_names" {
  description = "List of all node group names"
  value       = aws_eks_node_group.nodes[*].node_group_name  # 修改为正确的资源名称
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = aws_eks_cluster.main.status
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = var.cluster_name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN for the cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN for the nodes"
  value       = aws_iam_role.node.arn
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}
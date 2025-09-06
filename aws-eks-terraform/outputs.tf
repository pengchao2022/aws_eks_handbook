output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.cluster.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.cluster.endpoint
}

output "node_group_names" {
  description = "List of node group names"
  value       = [for ng in aws_eks_node_group.ubuntu_nodes : ng.node_group_name]
}

output "node_instance_names" {
  description = "List of node instance names"
  value       = var.node_instance_names
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${aws_eks_cluster.cluster.name}"
}
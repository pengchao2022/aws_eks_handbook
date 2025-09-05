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

output "node_group_arn" {
  description = "Node group ARN"
  value       = aws_eks_node_group.ubuntu_nodes.arn
}

output "launch_template_id" {
  description = "Launch template ID for Ubuntu nodes"
  value       = aws_launch_template.ubuntu_eks.id
}
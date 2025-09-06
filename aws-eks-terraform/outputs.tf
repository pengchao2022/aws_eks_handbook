output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ids attached to the worker nodes"
  value       = module.eks.node_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_managed_node_groups" {
  description = "Outputs of EKS managed node groups"
  value       = module.eks.eks_managed_node_groups
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = module.eks.cluster_status
}

# 移除不存在的 kubeconfig 输出，使用以下命令手动生成 kubeconfig：
# aws eks update-kubeconfig --region <region> --name <cluster-name>
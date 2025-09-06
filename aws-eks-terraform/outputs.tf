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

# 正确的 kubeconfig 输出
output "kubeconfig" {
  description = "Kubernetes configuration file content"
  value       = module.eks.kubeconfig_raw
  sensitive   = true
}

# 添加一些有用的输出
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = module.eks.cluster_status
}

output "node_group_status" {
  description = "Status of the node group"
  value       = module.eks.eks_managed_node_groups["ubuntu_nodes"].status
}
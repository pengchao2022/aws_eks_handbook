variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-development-cluster"
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "node_instance_names" {
  description = "List of EC2 instance names for worker nodes"
  type        = list(string)
  default     = ["eks-development-1", "eks-development-2", "eks-development-3", "eks-development-4"]
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 4
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 6
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 4
}

variable "instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "key_name" {
  description = "SSH key pair name for EC2 instances"
  type        = string
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
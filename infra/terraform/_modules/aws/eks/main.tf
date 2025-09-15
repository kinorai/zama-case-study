variable "cluster_name" { type = string }
variable "cluster_version" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "public_subnets" {
  type = list(string)
  default = []
}
variable "desired_capacity" { type = number }
variable "min_size" { type = number }
variable "max_size" { type = number }
variable "instance_types" { type = list(string) }

variable "enabled" {
  type        = bool
  description = "Whether to create the EKS cluster"
  default     = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  count = var.enabled ? 1 : 0

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_capacity
      instance_types = var.instance_types
      capacity_type  = "ON_DEMAND"
    }
  }
}

output "cluster_name" {
  value = length(module.eks) > 0 ? module.eks[0].cluster_name : null
}

output "cluster_endpoint" {
  value = length(module.eks) > 0 ? module.eks[0].cluster_endpoint : null
}

output "cluster_security_group_id" {
  value = length(module.eks) > 0 ? module.eks[0].cluster_security_group_id : null
}


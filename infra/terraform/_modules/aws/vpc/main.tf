variable "name" { type = string }
variable "cidr_block" { type = string }
variable "azs" { type = list(string) }

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = var.name
  cidr = var.cidr_block

  azs             = var.azs
  private_subnets = [for i in range(length(var.azs)) : cidrsubnet(var.cidr_block, 4, i)]
  public_subnets  = [for i in range(length(var.azs)) : cidrsubnet(var.cidr_block, 4, i + 8)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

output "vpc_id" { value = module.vpc.vpc_id }
output "private_subnets" { value = module.vpc.private_subnets }
output "public_subnets" { value = module.vpc.public_subnets }


terraform {
  source = "${get_repo_root()}/infra/terraform/_modules/aws/eks"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../foundation/vpc"
  mock_outputs = {
    vpc_id          = "vpc-000000"
    private_subnets = ["subnet-111111", "subnet-222222", "subnet-333333"]
    public_subnets  = ["subnet-aaaaaa", "subnet-bbbbbb", "subnet-cccccc"]
  }
}

inputs = {
  cluster_name     = "zama-prod-eks"
  cluster_version  = "1.29"
  vpc_id           = dependency.vpc.outputs.vpc_id
  private_subnets  = dependency.vpc.outputs.private_subnets
  public_subnets   = dependency.vpc.outputs.public_subnets
  desired_capacity = 2
  min_size         = 2
  max_size         = 4
  instance_types   = ["t3.medium"]
  enabled          = false
}


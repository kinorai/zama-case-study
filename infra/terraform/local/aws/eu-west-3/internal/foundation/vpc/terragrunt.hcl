terraform {
  source = "${get_repo_root()}/infra/terraform/_modules/aws/vpc"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  name       = "zama-prod-vpc"
  cidr_block = "10.20.0.0/16"
  azs        = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
}


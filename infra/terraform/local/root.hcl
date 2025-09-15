# Local Terragrunt root overriding remote state for LocalStack

locals {
  aws_region = "eu-west-3"
}

terraform {
  extra_arguments "common_vars" {
    commands = ["init", "plan", "apply", "destroy"]
    arguments = [
      "-lock-timeout=5m"
    ]
  }
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    eks = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    bucket           = "zama-terragrunt-state"
    key              = "${path_relative_to_include()}/terraform.tfstate"
    region           = local.aws_region
    encrypt          = true
    use_lockfile     = true
    endpoint         = "http://localhost:4566"
    use_path_style = true
  }
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {}
}
EOF
}

inputs = {
  aws_region = local.aws_region
}

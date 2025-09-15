# Root Terragrunt config for remote state, provider and versions

locals {
  aws_region = "eu-west-3" # Paris
}

terraform {
  extra_arguments "common_vars" {
    commands = ["init", "plan", "apply", "destroy"]
    arguments = [
      "-lock-timeout=5m"
    ]
  }
}

# Generate common provider and versions into each working directory
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
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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
  region = var.aws_region
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
    # NOTE: Ensure these are bootstrapped (or change to local backend) before first use
    bucket         = "zama-terragrunt-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    use_lockfile   = true
    force_path_style = true
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


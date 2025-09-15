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

# Ensure Helmignore is created before deploying the internal API
# ERROR: zama-internal-api/templates/tests/.terragrunt-source-manifest: error
# https://github.com/gruntwork-io/terragrunt/issues/943
  include_in_copy = [
    "${get_repo_root()}/infra/terraform/_modules/kubernetes/kube-prometheus-stack/kube-prometheus-stack/.helmignore",
  ]
  exclude_from_copy = [
    "**/.terragrunt-source-manifest",
  ]

  before_hook "ensure_helmignore" {
    commands = ["init", "plan", "apply"]
    execute  = ["bash", "-lc", "mkdir -p kube-prometheus-stack && printf '%s\n' '.DS_Store' '.git/' '.gitignore' '.hg/' '.svn/' '*.swp' '*.bak' '*.tmp' '*~' '.terragrunt-source-manifest' '.terragrunt-cache/' > kube-prometheus-stack/.helmignore"]
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
    bucket           = "zama-terragrunt-state"
    key              = "${path_relative_to_include()}/terraform.tfstate"
    region           = local.aws_region
    encrypt          = true
    use_lockfile     = true
    endpoint         = "http://localhost:4566"
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

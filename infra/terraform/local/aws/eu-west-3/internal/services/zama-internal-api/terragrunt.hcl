include "root" {
  path = find_in_parent_folders("root.hcl")
}
# Ensure Helmignore is created before deploying the internal API
# ERROR: zama-internal-api/templates/tests/.terragrunt-source-manifest: error
# https://github.com/gruntwork-io/terragrunt/issues/943
terraform {
  source = "${get_repo_root()}/infra/terraform/_modules/kubernetes/zama-internal-api"
  include_in_copy = [
    "${get_repo_root()}/infra/terraform/_modules/kubernetes/zama-internal-api/chart/.helmignore",
  ]
  exclude_from_copy = [
    "**/.terragrunt-source-manifest",
  ]

  before_hook "ensure_helmignore" {
    commands = ["init", "plan", "apply"]
    execute  = ["bash", "-lc", "mkdir -p chart && printf '%s\n' '.DS_Store' '.git/' '.gitignore' '.hg/' '.svn/' '*.swp' '*.bak' '*.tmp' '*~' '.terragrunt-source-manifest' '.terragrunt-cache/' > chart/.helmignore"]
  }
}

# Ensure PriorityClasses exist before deploying the internal API
dependency "priority_classes" {
  config_path  = "../priority-classes"
  skip_outputs = true
}

inputs = {
  kubeconfig_path = "~/.kube/kubeconfig-zama-local-k3d.yaml"
  # values_files = [
  #   "${get_repo_root()}/infra/terraform/_modules/kubernetes/zama-internal-api/chart/values.yaml",
  #   "${get_terragrunt_dir()}/values-local.yaml"
  # ]
  # API key is generated in the module; no need to set here
}



include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terraform/_modules/kubernetes/kube-prometheus-stack"

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

dependency "kong" {
  config_path  = "../kong"
  skip_outputs = true
}

inputs = {
  kubeconfig_path      = "~/.kube/kubeconfig-zama-local-k3d.yaml"
  values_override_file = "${get_terragrunt_dir()}/values-local.yaml"
  dashboards_dir       = "${get_repo_root()}/observability/grafana/dashboards"
}



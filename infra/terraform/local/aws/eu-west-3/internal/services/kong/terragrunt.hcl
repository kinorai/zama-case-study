include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terraform/_modules/kubernetes/kong"
}

# Ensure PriorityClasses exist before deploying Kong
dependency "priority_classes" {
  config_path  = "../priority-classes"
  skip_outputs = true
}

inputs = {
  kubeconfig_path      = "~/.kube/kubeconfig-zama-local-k3d.yaml"
  # namespace          = "kong"
  # release_name       = "kong"
  values_override_file = "${get_terragrunt_dir()}/values-local.yaml"
}

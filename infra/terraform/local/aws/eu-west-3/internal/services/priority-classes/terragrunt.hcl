include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/infra/terraform/_modules/kubernetes/priority-classes"
}

inputs = {
  kubeconfig_path = get_env("KUBECONFIG", "~/.kube/kubeconfig-zama-local-k3d.yaml")

  # Optional overrides; defaults already set in module
  # priority_classes = {
  #   "zama-critical" = { value = 1000000 }
  #   "zama-high"     = { value = 100000 }
  #   "zama-medium"   = { value = 10000 }
  #   "zama-low"      = { value = 1000 }
  # }

  labels = {
    "app.kubernetes.io/part-of"   = "zama"
    "app.kubernetes.io/component" = "scheduling"
    "zama.env"                    = "local"
  }

  allow_destroy = false
}



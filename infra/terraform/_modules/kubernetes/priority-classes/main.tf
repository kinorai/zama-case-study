variable "kubeconfig_path" {
  type = string
}

variable "namespace" {
  type    = string
  default = "kube-system"
}

variable "release_name" {
  type    = string
  default = "zama-priority-classes"
}

variable "chart_dir" {
  type    = string
  default = "zama-priority-classes"
}

variable "values_file" {
  type    = string
  default = "values.yaml"
}

variable "priority_classes" {
  description = "Map of priority class definitions (name => { value, description, globalDefault })"
  type = map(object({
    value         = number
    description   = optional(string)
    globalDefault = optional(bool, false)
  }))
  default = {
    "zama-critical" = { value = 1000000, description = "Zama critical priority", globalDefault = false }
    "zama-high"     = { value = 100000,  description = "Zama high priority",     globalDefault = false }
    "zama-medium"   = { value = 10000,   description = "Zama medium priority",   globalDefault = false }
    "zama-low"      = { value = 1000,    description = "Zama low priority",      globalDefault = false }
  }
}

variable "labels" {
  description = "Labels applied to PriorityClass objects"
  type        = map(string)
  default = {
    "app.kubernetes.io/part-of"  = "zama"
    "app.kubernetes.io/component" = "scheduling"
  }
}

variable "allow_destroy" {
  description = "Whether to allow destroying the Helm release (and thus PriorityClasses)"
  type        = bool
  default     = false
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

locals {
  rendered_values = yamlencode({
    priorityClasses = var.priority_classes
    labels          = var.labels
  })
}

resource "helm_release" "priority_classes" {
  name       = var.release_name
  namespace  = var.namespace
  chart      = "${path.module}/${var.chart_dir}"

  values = [
    file("${path.module}/${var.chart_dir}/${var.values_file}"),
    local.rendered_values
  ]

  # Prevent accidental destroy by default. Use allow_destroy=true to permit.
  lifecycle {
    prevent_destroy = true
  }
}

output "namespace" { value = var.namespace }
output "release_name" { value = helm_release.priority_classes.name }


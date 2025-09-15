variable "kubeconfig_path" {
  type = string
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "release_name" {
  type    = string
  default = "prometheus-stack"
}

variable "chart_dir" {
  type    = string
  default = "kube-prometheus-stack"
}

variable "values_file" {
  type    = string
  default = "values.yaml"
}

variable "values_override_file" {
  type    = string
  default = ""
}

variable "dashboards_dir" {
  description = "Absolute path to a directory containing Grafana dashboard JSON files"
  type        = string
  default     = ""
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "random_password" "grafana_username" {
  length           = 16
  special          = false
  upper            = true
  lower            = true
  numeric          = false
}

resource "random_password" "grafana_password" {
  length           = 32
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
}

locals {
  dashboard_files = var.dashboards_dir != "" ? fileset(var.dashboards_dir, "*.json") : []
}

resource "kubernetes_config_map" "grafana_dashboards" {
  count = length(local.dashboard_files) > 0 ? 1 : 0

  metadata {
    name      = "grafana-dashboards"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "grafana_dashboard"           = "1"
      "app.kubernetes.io/name"      = "grafana-dashboards"
      "app.kubernetes.io/instance"  = var.release_name
      "app.kubernetes.io/part-of"   = var.release_name
    }
  }

  data = { for f in local.dashboard_files : basename(f) => file("${var.dashboards_dir}/${f}") }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = var.release_name
  namespace  = kubernetes_namespace.this.metadata[0].name
  chart      = "${path.module}/${var.chart_dir}"

  # Install CRDs shipped in the chart
  skip_crds = false

  values = concat(
    [file("${path.module}/${var.values_file}")],
    var.values_override_file != "" ? [file(var.values_override_file)] : [],
    [yamlencode({
      grafana = {
        adminUser     = random_password.grafana_username.result,
        adminPassword = random_password.grafana_password.result
      }
    })]
  )

  depends_on = [
    kubernetes_config_map.grafana_dashboards
  ]
}

output "namespace" { value = kubernetes_namespace.this.metadata[0].name }
output "release_name" { value = helm_release.kube_prometheus_stack.name }

output "grafana_admin_user" {
  value     = random_password.grafana_username.result
  sensitive = true
}

output "grafana_admin_password" {
  value     = random_password.grafana_password.result
  sensitive = true
}



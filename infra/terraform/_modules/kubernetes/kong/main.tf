variable "kubeconfig_path" {
  type = string
}

variable "namespace" {
  type    = string
  default = "kong"
}

variable "release_name" {
  type    = string
  default = "kong"
}

variable "chart_dir" {
  type    = string
  default = "kong"
}

variable "values_file" {
  type    = string
  default = "values.yaml"
}

variable "values_override_file" {
  type    = string
  default = ""
}

variable "kong_declarative_config_file" {
  type    = string
  default = "kong.yml"
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

resource "kubernetes_config_map" "kong_config" {
  metadata {
    name      = "kong-config"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels = {
      "app.kubernetes.io/name"     = "kong-config"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
  data = {
    "kong.yml" = file("${path.module}/${var.kong_declarative_config_file}")
  }
}

resource "helm_release" "kong" {
  name       = var.release_name
  namespace  = kubernetes_namespace.this.metadata[0].name
  chart      = "${path.module}/${var.chart_dir}"

  # Install CRDs shipped in the chart (present under charts/kong/crds)
  skip_crds = false

  values = concat(
    [file("${path.module}/${var.values_file}")],
    var.values_override_file != "" ? [file(var.values_override_file)] : []
  )

  depends_on = [
    kubernetes_config_map.kong_config
  ]
}

output "namespace" { value = kubernetes_namespace.this.metadata[0].name }
output "release_name" { value = helm_release.kong.name }


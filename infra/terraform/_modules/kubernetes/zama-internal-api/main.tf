variable "kubeconfig_path" {
  type = string
}

variable "namespace" {
  type    = string
  default = "zama-internal-api"
}

variable "release_name" {
  type    = string
  default = "zama-internal-api"
}

variable "chart_dir" {
  type    = string
  default = "chart"
}

variable "values_override_file" {
  type    = string
  default = ""
}

variable "values_files" {
  type    = list(string)
  default = ["chart/values.yaml"]
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

resource "random_password" "api_key" {
  length           = 32
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
}

 

resource "helm_release" "app" {
  name      = var.release_name
  namespace = kubernetes_namespace.this.metadata[0].name
  chart     = "${path.module}/${var.chart_dir}"
  values    = concat(
    [for f in var.values_files : file("${path.module}/${f}")],
    var.values_override_file != "" ? [file(var.values_override_file)] : [],
    [yamlencode({
      secret = {
        enabled    = true,
        stringData = {
          API_KEY = random_password.api_key.result
        }
      }
    })]
  )
 
}

output "namespace" { value = kubernetes_namespace.this.metadata[0].name }
output "release_name" { value = helm_release.app.name }

output "api_key" {
  value     = random_password.api_key.result
  sensitive = true
}


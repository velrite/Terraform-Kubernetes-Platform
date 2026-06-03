variable "namespace" {
  type = string
}

variable "grafana_password" {
  type      = string
  sensitive = true
}

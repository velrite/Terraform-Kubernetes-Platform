variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}
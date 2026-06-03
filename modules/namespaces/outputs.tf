output "microservices_namespace" {
  value = kubernetes_namespace.microservices.metadata[0].name
}

output "monitoring_namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

output "vault_namespace" {
  value = kubernetes_namespace.vault.metadata[0].name
}

output "opencost_namespace" {
  value = kubernetes_namespace.opencost.metadata[0].name
}

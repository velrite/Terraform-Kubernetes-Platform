resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.namespace
  timeout          = 600
  create_namespace = false

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "7d"
  }
  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "grafana.resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "grafana.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_password
  }
  set {
    name  = "nodeExporter.resources.requests.memory"
    value = "32Mi"
  }
  set {
    name  = "nodeExporter.resources.limits.memory"
    value = "64Mi"
  }
  set {
    name  = "kubeStateMetrics.resources.requests.memory"
    value = "32Mi"
  }
  set {
    name  = "kubeStateMetrics.resources.limits.memory"
    value = "64Mi"
  }
}
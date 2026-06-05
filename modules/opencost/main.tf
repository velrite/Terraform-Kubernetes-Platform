resource "helm_release" "opencost" {
  name             = "opencost"
  repository       = "https://opencost.github.io/opencost-helm-chart"
  chart            = "opencost"
  namespace        = var.namespace
  timeout          = 300
  create_namespace = false

  set {
    name  = "opencost.exporter.defaultClusterId"
    value = "prod-sim"
  }
  set {
    name  = "opencost.prometheus.internal.enabled"
    value = "false"
  }
  set {
    name  = "opencost.prometheus.external.enabled"
    value = "true"
  }
  set {
    name  = "opencost.prometheus.external.url"
    value = "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
  }
}
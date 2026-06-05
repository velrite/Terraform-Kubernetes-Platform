resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = var.namespace
  timeout          = 300
  create_namespace = false

  set {
    name  = "server.dev.enabled"
    value = "true"
  }
  set {
    name  = "server.dev.devRootToken"
    value = "root"
  }
  set {
    name  = "server.resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "server.resources.limits.memory"
    value = "256Mi"
  }
}

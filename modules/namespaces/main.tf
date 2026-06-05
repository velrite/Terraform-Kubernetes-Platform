resource "kubernetes_namespace" "microservices" {
  metadata {
    name = "microservices"
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace" "opencost" {
  metadata {
    name = "opencost"
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}
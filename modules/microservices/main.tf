resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-secret"
    namespace = var.namespace
  }
  data = {
    POSTGRES_PASSWORD = var.postgres_password
    POSTGRES_USER     = var.postgres_user
    POSTGRES_DB       = var.postgres_db
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres-db"
    namespace = var.namespace
    labels = {
      app         = "postgres-db"
      tier        = "database"
      managed-by  = "terraform"
      cost-center = "platform"
      team        = "data"
      environment = var.environment
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "postgres-db"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgres-db"
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:14-alpine"
          port {
            container_port = 5432
          }
          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }
          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "api_service" {
  metadata {
    name      = "api-service"
    namespace = var.namespace
    labels = {
      app         = "api-service"
      managed-by  = "terraform"
      cost-center = "platform"
      team        = "backend"
      environment = var.environment
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "api-service"
      }
    }
    template {
      metadata {
        labels = {
          app = "api-service"
        }
      }
      spec {
        container {
          name  = "api-service"
          image = "nginx:alpine"
          port {
            container_port = 80
          }
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend"
    namespace = var.namespace
    labels = {
      app         = "frontend"
      managed-by  = "terraform"
      cost-center = "product"
      team        = "frontend"
      environment = var.environment
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "frontend"
      }
    }
    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }
      spec {
        container {
          name  = "frontend"
          image = "nginx:alpine"
          port {
            container_port = 80
          }
          resources {
            requests = {
              cpu    = "25m"
              memory = "32Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api_service" {
  metadata {
    name      = "api-service"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = "api-service"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = "frontend"
    }
    port {
      port        = 80
      target_port = 80
      node_port   = 30421
    }
    type = "NodePort"
  }
}

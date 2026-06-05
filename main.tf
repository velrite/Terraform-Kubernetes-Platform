terraform {
  required_version = ">= 1.7.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "prod-sim"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "prod-sim"
  }
}

module "namespaces" {
  source      = "./modules/namespaces"
  environment = var.environment
}

module "microservices" {
  source            = "./modules/microservices"
  namespace         = module.namespaces.microservices_namespace
  environment       = var.environment
  postgres_password = var.postgres_password
  postgres_user     = var.postgres_user
  postgres_db       = var.postgres_db
  depends_on        = [module.namespaces]
}

module "monitoring" {
  source           = "./modules/monitoring"
  namespace        = module.namespaces.monitoring_namespace
  grafana_password = var.grafana_password
  depends_on       = [module.namespaces]
}

module "vault" {
  source     = "./modules/vault"
  namespace  = module.namespaces.vault_namespace
  depends_on = [module.namespaces]
}

module "opencost" {
  source     = "./modules/opencost"
  namespace  = module.namespaces.opencost_namespace
  depends_on = [module.monitoring]
}
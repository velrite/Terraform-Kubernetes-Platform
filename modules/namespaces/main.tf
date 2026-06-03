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
  grafana_password = "REDACTED"
  depends_on       = [module.namespaces]
}

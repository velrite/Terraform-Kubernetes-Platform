variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
}
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "prod-sim"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "appuser"
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "namespace" {
  type = string
}

variable "environment" {
  type = string
}

variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "postgres_user" {
  type = string
}

variable "postgres_db" {
  type = string
}

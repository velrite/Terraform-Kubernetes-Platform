# Terraform Kubernetes Platform

Provisions a complete production-grade Kubernetes platform declaratively.
Clone the repo, run `terraform apply`, get the exact same infrastructure.

## Prerequisites
- Minikube running with prod-sim profile
- kubectl configured
- Terraform >= 1.7.0

## How to run
terraform init
terraform apply -auto-approve

## Destroy and rebuild
terraform destroy -auto-approve
terraform apply -auto-approve

## What gets provisioned
- 4 namespaces: microservices, monitoring, vault, opencost
- 3 deployments: api-service, frontend, postgres-db
- 2 services: api-service (ClusterIP), frontend (NodePort)
- 1 secret: postgres credentials (sensitive, never hardcoded)
- Prometheus + Grafana via Helm
- HashiCorp Vault via Helm
- OpenCost cost visibility via Helm

## Module structure
- modules/namespaces — all namespace definitions
- modules/microservices — deployments, services, secrets
- modules/monitoring — Prometheus + Grafana
- modules/vault — HashiCorp Vault
- modules/opencost — OpenCost cost visibility

## Security
- All secrets defined as sensitive variables
- No credentials hardcoded anywhere
- terraform.tfvars excluded from git via .gitignore

## Resources managed by Terraform
- 13 total resources
- 4 namespaces
- 3 deployments
- 2 services
- 1 secret
- 3 helm releases

## Connected to
[Auto-healing Kubernetes Platform](https://github.com/velrite/auto-healing-k8s--)
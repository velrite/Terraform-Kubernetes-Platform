# Architecture

## How Terraform Manages This Platform

Terraform operates in three phases:

```
terraform plan
  → reads current state from terraform.tfstate
  → reads desired state from .tf files
  → computes diff
  → prints what will change

terraform apply
  → executes the plan
  → creates/updates/deletes resources
  → writes new state to terraform.tfstate

terraform destroy
  → destroys all resources in state
  → removes state entries
```

The state file is the source of truth for what Terraform owns.
If a resource exists in the cluster but not in state, Terraform ignores it.
If a resource is in state but not in .tf files, Terraform will destroy it on next apply.

---

## Provider Configuration

```hcl
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
```

Both providers read from the same kubeconfig context.
Context must exist before `terraform apply` runs.
`aws eks update-kubeconfig` or `minikube start` creates this context.

---

## Module Dependency Order

```
namespaces (no dependencies)
    │
    ├──► microservices (depends_on namespaces)
    ├──► monitoring    (depends_on namespaces)
    ├──► vault         (depends_on namespaces)
    └──► opencost      (depends_on monitoring)
                              │
                         needs Prometheus URL
                         from monitoring module
```

`depends_on` blocks enforce this order explicitly.
Without them, Terraform might try to deploy a pod into a namespace
that does not yet exist, causing a creation failure.

---

## Sensitive Variable Handling

```hcl
variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true    # Terraform never prints this in logs
}
```

Variables marked `sensitive = true`:
- Never appear in `terraform plan` output
- Never appear in `terraform apply` output
- Stored in state file (which is gitignored)
- Must be provided via terraform.tfvars (gitignored) or environment variable

---

## What Terraform Does NOT Manage

- The Minikube cluster itself (started manually)
- The docker-proxy fix (manual step on each Codespace)
- Kubernetes RBAC beyond default namespacing
- HPA configuration (defined in manifests/, not Terraform)
- Prometheus alert rules (defined in monitoring/alert-rules.yaml)

These are applied separately with kubectl after `terraform apply`.


# Architecture

## How Terraform Works Here

```
terraform plan
  → reads current state from terraform.tfstate
  → reads desired state from .tf files
  → computes diff and prints what will change

terraform apply
  → executes plan
  → creates/updates/deletes resources
  → writes new state to terraform.tfstate
```

State file is the record of what Terraform owns.
Resource in cluster but not in state — Terraform ignores it.
Resource in state but not in .tf files — Terraform destroys it on next apply.

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

Both providers use the same kubeconfig context.
Context must exist before terraform apply.
minikube start creates this context automatically.

---

## Module Dependency Order

```
namespaces (no dependencies)
    │
    ├──► microservices (depends_on namespaces)
    ├──► monitoring    (depends_on namespaces)
    ├──► vault         (depends_on namespaces)
    └──► opencost      (depends_on monitoring)
```

depends_on enforces this order.
Without it Terraform might deploy a pod before its namespace exists.

---

## Sensitive Variables

```hcl
variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "grafana_password" {
  type      = string
  sensitive = true
}
```

sensitive = true means Terraform never prints these values
in plan or apply output. Stored in terraform.tfstate which is gitignored.
Values provided only via terraform.tfvars which is also gitignored.

---

## What Terraform Does Not Manage

- The Minikube cluster itself
- The docker-proxy fix
- HPA configuration (in manifests/, applied with kubectl)
- Prometheus alert rules (in monitoring/alert-rules.yaml)
- Vault initialization and unsealing

These are applied separately after terraform apply.

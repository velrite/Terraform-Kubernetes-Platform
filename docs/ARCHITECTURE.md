# Architecture

## How Terraform works in this project

terraform plan reads terraform.tfstate and the *.tf files, prints the difference
terraform apply executes the plan through the Kubernetes and Helm APIs, updates state
terraform destroy removes every resource recorded in state


State is the record of what Terraform owns. A cluster object that is not in state is invisible to Terraform. A resource in state that is removed from the code is destroyed on the next apply.

## Providers

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

Both read the `prod-sim` context created by `minikube start --profile=prod-sim`. If the cluster does not exist, the providers cannot connect and apply is blocked. Exact version constraints are in `main.tf`.

## Modules and order

| Module | Contains | Depends on | Why |
| ------ | -------- | ---------- | --- |
| namespaces | 4 namespaces labelled `managed-by=terraform` | none | Everything else deploys into them |
| microservices | postgres secret, 3 deployments, 2 services | namespaces | Pods cannot schedule without their namespace |
| monitoring | kube-prometheus-stack Helm release | namespaces | Release targets the monitoring namespace |
| vault | Vault Helm release, dev mode | namespaces | Release targets the vault namespace |
| opencost | OpenCost Helm release | monitoring | OpenCost reads cost data from that Prometheus |

The `managed-by=terraform` label is functional: `kubectl get namespaces -l managed-by=terraform` answers "which namespaces does Terraform own", which matters once Helm, Argo CD and manual kubectl share a cluster.

## The sensitive-value path

terraform.tfvars (gitignored) -> sensitive variable -> kubernetes_secret
-> Deployment references the secret by key


The Deployment object in the cluster carries a secret reference, not the value. The value exists in the Kubernetes secret and in `terraform.tfstate`.

## Helm configuration

Limits and passwords are passed as `set` blocks so they are visible in plan output and state. The memory limits for Prometheus and Grafana are reduced because the chart defaults allocate about 2 GB to Prometheus alone, which does not fit beside a multi-node cluster, Vault and OpenCost on an 8 GB machine.

## What Terraform does not manage

- The Minikube cluster itself
- HPA configuration (in the Auto-Healing project's manifests, applied with kubectl)
- Prometheus alert rules
- Vault secret engines, roles and policies (dev mode needs no initialisation)
- Remote state and workspaces (not built, see [GAPS.md](GAPS.md))
- The Kubernetes objects inside the three Helm releases

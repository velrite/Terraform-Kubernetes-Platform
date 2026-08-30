# Terraform Kubernetes Platform

> The same platform as Project 1 — rebuilt entirely as code. Every resource defined declaratively. Reproducible with one command.

**Author:** Olamide Olalekan — Platform & DevSecOps Engineer
**GitHub:** [github.com/velrite](https://github.com/velrite)
**LinkedIn:** [linkedin.com/in/olamide-olalekan-12138a265](https://linkedin.com/in/olamide-olalekan-12138a265)
**Email:** velrite.tech@gmail.com

**Connects to:**
- [Project 1 — Auto-Healing Kubernetes Platform](https://github.com/velrite/auto-healing-k8s--)
- [Project 3 — GitOps ArgoCD Platform](https://github.com/velrite/gitops-argocd-platform)

---

## The Problem This Solves

In Project 1 every component was applied manually:
- `kubectl apply` for each manifest
- `helm install` for each tool
- Manual namespace creation
- Manual secret creation

If the cluster is destroyed, rebuilding requires remembering every command
in the correct order. There is no single record of what the platform is.

This project eliminates that. The Terraform code IS the record.
Destroy everything and run `terraform apply` — identical platform in minutes.

---

## Proven

```bash
terraform state list
# 13 resources all managed by Terraform

terraform destroy -auto-approve
# All 13 resources destroyed

terraform apply -auto-approve
# All 13 resources recreated identically
```

[SCREENSHOT: terraform state list showing all 13 resources]
[SCREENSHOT: terraform apply output showing Apply complete! Resources: 13 added]

---

## Resources Managed (13 total)

| Resource | Type | Module |
|----------|------|--------|
| microservices namespace | kubernetes_namespace | namespaces |
| monitoring namespace | kubernetes_namespace | namespaces |
| vault namespace | kubernetes_namespace | namespaces |
| opencost namespace | kubernetes_namespace | namespaces |
| postgres-secret | kubernetes_secret | microservices |
| postgres-db deployment | kubernetes_deployment | microservices |
| api-service deployment | kubernetes_deployment | microservices |
| frontend deployment | kubernetes_deployment | microservices |
| api-service service | kubernetes_service | microservices |
| frontend service | kubernetes_service | microservices |
| Prometheus + Grafana | helm_release | monitoring |
| HashiCorp Vault | helm_release | vault |
| OpenCost | helm_release | opencost |

---

## Module Structure

```
terraform/
├── main.tf                 — providers, backend config, module calls
├── variables.tf            — all input variables with types and descriptions
├── terraform.tfvars        — variable values (gitignored — never committed)
└── modules/
    ├── namespaces/         — 4 Kubernetes namespaces
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── microservices/      — deployments, services, postgres secret
    │   ├── main.tf
    │   └── variables.tf
    ├── monitoring/         — Prometheus + Grafana Helm release
    │   ├── main.tf
    │   └── variables.tf
    ├── vault/              — HashiCorp Vault Helm release
    │   ├── main.tf
    │   └── variables.tf
    └── opencost/           — OpenCost Helm release
        ├── main.tf
        └── variables.tf
```

---

## Quick Start

### Prerequisites
- Minikube running with prod-sim profile
- kubectl configured
- Terraform >= 1.7.0
- Helm >= 3.0

### Deploy
```bash
terraform init
terraform plan    # Review what will be created
terraform apply -auto-approve
kubectl get pods --all-namespaces
```

### Destroy
```bash
terraform destroy -auto-approve
```

---

## CI/CD Security Pipeline

Every push and pull request runs:

```
push to main
  └── Security Scan
  │     ├── TruffleHog    — scans for hardcoded secrets and credentials
  │     ├── tfsec         — scans Terraform for security misconfigurations
  │     └── Checkov       — validates compliance policies
  └── Validate
        ├── terraform fmt -check  — enforces consistent formatting
        ├── terraform init        — initializes providers
        └── terraform validate    — validates syntax and configuration
```

[SCREENSHOT: GitHub Actions showing Security Scan and Validate both green]

Security runs first. If any credential is found in code,
the pipeline stops immediately. Nothing proceeds.

---

## Documentation

| Document | What It Covers |
|----------|---------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Module design, provider config, dependency order |
| [SECURITY.md](docs/SECURITY.md) | Sensitive variables, git hygiene, credential incident |
| [ADR.md](docs/ADR.md) | Why each tool and pattern was chosen |
| [INCIDENTS.md](docs/INCIDENTS.md) | Real problems — hardcoded password, file corruption |
| [GAPS.md](docs/GAPS.md) | Remote state, workspace separation, apply in CI |

---

## Author

Olamide Olalekan — Platform & DevSecOps Engineer
GitHub: [github.com/velrite](https://github.com/velrite)
LinkedIn: [linkedin.com/in/olamide-olalekan-12138a265](https://linkedin.com/in/olamide-olalekan-12138a265)

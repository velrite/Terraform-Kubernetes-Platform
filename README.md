# Terraform Kubernetes Platform

The same platform as Project 1 — rebuilt entirely as code.
Every namespace, deployment, service, and Helm release defined in Terraform.
Destroy everything. Run one command. Identical platform back in minutes.

**Author:** Olamide Olalekan — Platform & DevSecOps Engineer
**GitHub:** [github.com/velrite](https://github.com/velrite)
**LinkedIn:** [linkedin.com/in/olamide-olalekan-12138a265](https://linkedin.com/in/olamide-olalekan-12138a265)
**Email:** velrite.tech@gmail.com

---

## The Problem This Solves

In Project 1 everything was applied manually.  the cluster is destroyed,
rebuilding requires remembering every command in the correct order.
There is no single record of what the platform is.

This project eliminates that. The Terraform code is the record.
Destroy everything and run `terraform apply` — identical platform.

---

## Proven

```bash
terraform state list
# 13 resources all managed by Terraform
```

[SCREENSHOT: terraform state list showing all 13 resources]
[SCREENSHOT: terraform apply output showing Apply complete! Resources: 13 added]
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
├── main.tf              — providers, module calls
├── variables.tf         — input variables with sensitive = true
├─�erraform.tfvars     — values (gitignored — never committed)
└── modules/
    ├── namespaces/      — 4 Kubernetes namespaces
    ├── microservices/   — deployments, services, postgres secret
    ├── monitoring/      — Prometheus + Grafana Helm release
    ├── vault/           — HashiCorp Vault Helm release
    └── opencost/        — OpenCost Helm release
```

---

## Quick Start

```bash
terraform init
terraform plan
terraform apply -auto-approve
kubectl get pods --all-namespaces
```

Destroy:
```bash
terraform destroy -auto-approve
```

---

## CI/CD Security Pipeline

Every push runs:

```
Security Scan
  ├── TruffleHog  — scans for hardcoded secrets
  ├── tfsec       — Terraform security misconfigurations
  └── Checkov     — compliance policy violations

Validate
  ├── terraform fmt -check  — formatting check
  ├── terraform init        — provider initialization
  └── terraform validate    — syntax and configuration check
```

[SCREENSHOT: GitHub Actions showing Security Scan and Validate both green]

Security runs first. Credential found means pipeline stops immediately.

---

## Documentation

| File | Contents |
|------|----------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Module design, provider config, dependency order |
| [SECURITY.md](docs/SECURITY.md) | Sensitive variables, credential incident and fix |
| [ADR.md](docs/ADR.md) | Every decision with alternatives rejected |
| [INCIDENTS.md](docs/INCIDENTS.md) | Hardcoded password, corrupted files, 0 resources bug |
| [GAPS.md](docs/GAPS.md) | Remote state, workspaces, apply in CI |

---

## Related Projects

- [Project 1 — Auto-Healing Kubernetes Platform](https://github.com/velrite/auto-healing-k8s--) — what this provisions manually
- [Project 3 — GitOps ArgoCD Platform](https://github.com/velrite/gitops-argocd-platform) — ArgoCD provisioned using this pattern

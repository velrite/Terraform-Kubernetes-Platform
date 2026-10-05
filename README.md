# Terraform Kubernetes Platform

The same platform as the Auto-Healing Kubernetes project — rebuilt entirely as infrastructure code.

**Author:** Olamide Olalekan — Platform & DevSecOps Engineer
**GitHub:** [github.com/velrite](https://github.com/velrite)
**LinkedIn:** [linkedin.com/in/olamide-olalekan-12138a265](https://linkedin.com/in/olamide-olalekan-12138a265)
**Email:** velrite.tech@gmail.com

---

## Why This Project Exists

The Auto-Healing Kubernetes project was built by running commands manually — `kubectl apply`, `helm install`, namespace creation, secret creation. It worked. But if the cluster was destroyed, rebuilding it required remembering every command in the correct order from memory.

That is not infrastructure. That is tribal knowledge.

This project answers a different question:

> Can the platform be reproduced from code rather than from remembered manual steps?

The Terraform configuration is the answer. It is the authoritative description of the infrastructure. Destroy everything. Run one command. The platform comes back identically.

---

## Verified

```bash
terraform state list | wc -l
# 13

terraform plan
# No changes. Your infrastructure matches the configuration.
```

[SCREENSHOT: docs/evidence/01-terraform-state-list.png]
[SCREENSHOT: docs/evidence/02-terraform-plan-no-changes.png]

---

## Resources Managed (13 total)

| # | Resource | Type | Module |
|---|----------|------|--------|
| 1 | microservices | kubernetes_namespace | namespaces |
| 2 | monitoring | kubernetes_namespace | namespaces |
| 3 | vault | kubernetes_namespace | namespaces |
| 4 | opencost | kubernetes_namespace | namespaces |
| 5 | postgres-secret | kubernetes_secret | microservices |
| 6 | postgres-db | kubernetes_deployment | microservices |
| 7 | api-service | kubernetes_deployment | microservices |
| 8 | frontend | kubernetes_deployment | microservices |
| 9 | api-service ClusterIP | kubernetes_service | microservices |
| 10 | frontend NodePort | kubernetes_service | microservices |
| 11 | Prometheus + Grafana | helm_release | monitoring |
| 12 | HashiCorp Vault | helm_release | vault |
| 13 | OpenCost | helm_release | opencost |

---

## Module Architecture

```
Terraform
    │
    ├── modules/namespaces/
    │       Creates 4 namespaces with managed-by=terraform labels
    │       All other modules depend on this
    │
    ├── modules/microservices/
    │       Deployments, services, postgres secret
    │       Credentials passed as sensitive variables — never hardcoded
    │
    ├── modules/monitoring/
    │       kube-prometheus-stack Helm release
    │       Resource limits tuned for 8GB Codespace
    │
    ├── modules/vault/
    │       HashiCorp Vault Helm release
    │       Dev mode — see ADR-001
    │
    └── modules/opencost/
            OpenCost Helm release
            Configured to use existing Prometheus — no bundled Prometheus
```

Dependency order enforced with `depends_on`:
```
namespaces → microservices
namespaces → monitoring
namespaces → vault
monitoring → opencost
```

Without this ordering Terraform might deploy a pod before its namespace exists.

[SCREENSHOT: docs/evidence/03-module-structure.png]

---

## Current Scope

**Terraform manages:**
- Namespaces
- Kubernetes deployments and services
- Kubernetes secrets (values from sensitive variables)
- Helm releases for all platform tools

**Not currently managed by Terraform:**
- The Minikube cluster itself
- HPA configuration (in manifests/, applied separately)
- Prometheus alert rules (in monitoring/alert-rules.yaml)
- Vault initialization and unsealing
- Remote state (local only — see GAPS.md)
- Workspaces (single environment — see GAPS.md)

These boundaries are documented rather than pretended away.

---

## Security: Sensitive Variables

All credentials use `sensitive = true`. Terraform enforces they never appear in plan or apply output.

```hcl
variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}
```

Values provided only via `terraform.tfvars` which is excluded from Git.

[SCREENSHOT: docs/evidence/04-sensitive-variables.png]

---

## Security Incident: Credential in Git History

During the build, a Grafana password was hardcoded directly in `main.tf` and pushed to a public GitHub repository.

```hcl
# What happened — never do this
grafana_password = "admin123secure"
```

### Response

1. Removed the value from the working tree immediately
2. Replaced with `var.grafana_password`
3. Rewrote entire Git history using `git-filter-repo`
4. Force-pushed the cleaned history
5. Verified no trace remained:

```bash
git log --all -p | grep -i "admin123"
# Returns nothing
echo "Exit code: $?"
# 1
```

### What this demonstrates

Secret scanning catches credentials before they are pushed. It does not help when credentials have already entered history. The remediation requires history rewriting and post-cleanup verification — not just removing the value from the current file.

The CI pipeline now runs TruffleHog on every push to catch future occurrences before they reach the repository.

[SCREENSHOT: docs/evidence/06-clean-git-history.png]

---

## CI/CD Security Pipeline

Every push runs security first. If a credential is found, the pipeline stops before anything else runs.

```
push to main
    │
    └── Security Scan
    │       ├── TruffleHog    — scans commits for hardcoded secrets
    │       ├── tfsec         — scans Terraform for security misconfigurations
    │       └── Checkov       — validates compliance policies
    │
    └── Validate
            ├── terraform fmt -check    — enforces consistent formatting
            ├── terraform init          — provider initialization
            └── terraform validate      — syntax and configuration check
```

[SCREENSHOT: docs/evidence/05-ci-pipeline-green.png]

---

## Quick Start

```bash
cd terraform/
terraform init
terraform plan \
  -var="postgres_password=apppassword" \
  -var="grafana_password=yourpassword"
terraform apply -auto-approve \
  -var="postgres_password=apppassword" \
  -var="grafana_password=yourpassword"
kubectl get pods --all-namespaces
```

Destroy:
```bash
terraform destroy -auto-approve \
  -var="postgres_password=apppassword" \
  -var="grafana_password=yourpassword"
```

---

## Documentation

| File | Contents |
|------|----------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | How Terraform manages state, providers, dependency order |
| [SECURITY.md](docs/SECURITY.md) | Sensitive variables, credential incident and fix |
| [ADR.md](docs/ADR.md) | Every decision with alternatives rejected |
| [INCIDENTS.md](docs/INCIDENTS.md) | Hardcoded password, corrupted files, 0 resources bug |
| [GAPS.md](docs/GAPS.md) | Remote state, workspaces, apply in CI |

---

## Related Projects

- [Auto-Healing Kubernetes Platform](https://github.com/velrite/auto-healing-k8s--) — the platform this provisions
- [GitOps ArgoCD Platform](https://github.com/velrite/gitops-argocd-platform) — uses the same Terraform pattern to provision ArgoCD

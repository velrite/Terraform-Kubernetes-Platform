# Terraform Kubernetes Platform

**A reproducible Kubernetes platform managed through Terraform, Kubernetes resources, and Helm releases.**

This repository takes the platform built in the [Auto-Healing Kubernetes project](https://github.com/velrite/auto-healing-k8s--) and expresses its application-layer infrastructure as code. The goal is to reduce dependence on remembered terminal commands and make resource ownership, dependency order, configuration, and operational boundaries explicit.

**Author:** Olamide Olalekan — Platform & DevSecOps Engineer  
**GitHub:** [github.com/velrite](https://github.com/velrite)  
**LinkedIn:** [linkedin.com/in/olamide-olalekan-12138a265](https://linkedin.com/in/olamide-olalekan-12138a265)  
**Email:** velrite.tech@gmail.com

[Project purpose](#engineering-problem) · [Architecture](#architecture) · [Managed resources](#managed-resources) · [Security](#security-design) · [CI validation](#ci-validation) · [Getting started](#getting-started) · [Documentation](#documentation) · [Related projects](#related-projects)

---

## Engineering problem

The original platform was assembled with direct commands such as `kubectl apply`, `helm install`, namespace creation, and secret creation. That can produce a working environment, but the build procedure becomes fragile when the cluster is deleted, the environment changes, or another engineer must reproduce it.

**A platform should be described by version-controlled configuration—not by an operator's memory.**

This project uses Terraform to declare Kubernetes namespaces, workloads, services, sensitive inputs, and Helm-managed platform components. Terraform's state and plan provide a view of what it manages and whether the declared configuration differs from the recorded infrastructure.

The intended outcome is repeatable provisioning with explicit dependencies. It is not a claim that every layer of the underlying environment is created by Terraform: the Minikube cluster itself, for example, remains outside this repository's Terraform-managed scope.

## Platform at a glance

| Area | Implementation | Responsibility |
|---|---|---|
| Infrastructure as code | Terraform | Declares resources, inputs, and dependencies |
| Kubernetes provider | `hashicorp/kubernetes` | Manages Kubernetes resources |
| Helm provider | `hashicorp/helm` | Installs and manages platform charts |
| Application workloads | Kubernetes Deployments and Services | Runs the sample database, API, and frontend components |
| Namespace isolation | Terraform namespace module | Creates namespaces for application and platform components |
| Monitoring | `kube-prometheus-stack` | Provides Prometheus and Grafana through Helm |
| Secrets | Terraform sensitive variables and Kubernetes Secret resource | Supplies application credentials through variables rather than hardcoded configuration |
| Secrets management platform | HashiCorp Vault Helm release | Deploys Vault; the repository documents its development-mode limitation |
| Cost visibility | OpenCost Helm release | Adds Kubernetes cost-attribution tooling |
| Validation and security | Terraform validation plus CI security tools described by the project | Checks configuration and scans for common security issues |

## Architecture

The root Terraform configuration composes four modules. Namespace creation is a prerequisite for the resources deployed into those namespaces; OpenCost is ordered after monitoring because its configuration uses the existing Prometheus installation.

![Terraform Kubernetes Platform — repository overview](Screenshot%202026-06-04%20155821.png)

### Terraform module composition

```text
Root Terraform configuration
│
├── modules/namespaces/
│   └── Creates the platform namespaces
│
├── modules/microservices/
│   └── PostgreSQL Secret, database, API, frontend, and Services
│
├── modules/monitoring/
│   └── kube-prometheus-stack Helm release
│
├── modules/vault/
│   └── HashiCorp Vault Helm release
│
└── modules/opencost/
    └── OpenCost Helm release, configured to use existing Prometheus
```

### Dependency order

```text
namespaces ──> microservices
     │
     ├───────> monitoring ──> opencost
     │
     └───────> vault
```

The root configuration expresses these relationships using module outputs and `depends_on`. This makes the intended creation order explicit rather than relying on a sequence of manual commands. Terraform still requires a valid Kubernetes context and a reachable cluster before it can manage Kubernetes resources.

## Managed resources

The project's original verification record reports **13 Terraform-managed resources**. The table below reflects that recorded inventory; resource counts can change as the configuration evolves.

| # | Resource described in the project | Terraform resource type | Module |
|---:|---|---|---|
| 1 | `microservices` namespace | `kubernetes_namespace` | `namespaces` |
| 2 | `monitoring` namespace | `kubernetes_namespace` | `namespaces` |
| 3 | `vault` namespace | `kubernetes_namespace` | `namespaces` |
| 4 | `opencost` namespace | `kubernetes_namespace` | `namespaces` |
| 5 | PostgreSQL Secret | `kubernetes_secret` | `microservices` |
| 6 | PostgreSQL database | `kubernetes_deployment` | `microservices` |
| 7 | API service workload | `kubernetes_deployment` | `microservices` |
| 8 | Frontend workload | `kubernetes_deployment` | `microservices` |
| 9 | API ClusterIP Service | `kubernetes_service` | `microservices` |
| 10 | Frontend NodePort Service | `kubernetes_service` | `microservices` |
| 11 | Prometheus and Grafana | `helm_release` | `monitoring` |
| 12 | HashiCorp Vault | `helm_release` | `vault` |
| 13 | OpenCost | `helm_release` | `opencost` |

To verify the current state in the configured environment:

```bash
terraform state list
terraform plan
```

A previous project record reported 13 state entries and a no-change plan. Those are point-in-time results, not a guarantee about a future environment. Re-run the commands against the intended cluster and state before relying on them.

![Terraform Kubernetes Platform — additional project screenshot](Screenshot%202026-06-05%20081526.png)

## What Terraform manages—and what it does not

### Managed by this configuration

- Kubernetes namespaces.
- Kubernetes Deployments and Services for the sample workloads.
- A Kubernetes Secret populated through Terraform input variables.
- Helm releases for monitoring, Vault, and OpenCost.
- Module inputs and dependency relationships.

### Outside the current Terraform-managed scope

- The Minikube cluster itself.
- HPA configuration described as being applied separately.
- Prometheus alert rules described as separate manifests.
- Vault initialization and unsealing.
- Remote Terraform state; the project documentation identifies state as local.
- Multi-environment Terraform workspaces; the project is described as a single-environment setup.

These boundaries matter operationally. Terraform cannot recreate infrastructure it does not declare, and local state introduces collaboration and recovery limitations. Treat the current implementation as an infrastructure-as-code project with documented scope—not as a complete, multi-environment platform lifecycle.

## Security design

### Sensitive inputs

The Terraform configuration declares credential variables with `sensitive = true`. This reduces accidental disclosure in normal Terraform CLI output, but it is **not a complete secret-management boundary**: sensitive values may still be present in state, provider interactions, or other systems depending on how the configuration is implemented.

Use unique credentials and supply them through an approved secret-delivery method. Do not commit `terraform.tfvars` or real credentials to version control. Review state storage and access before using this pattern in a shared or production environment.

Example variable declaration:

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

### Credential exposure incident and remediation

During development, a Grafana credential was committed to a public repository. The project record describes removing the value from the working tree, replacing it with a variable, rewriting Git history, force-pushing the cleaned history, and checking the available history for the exposed string.

The important operational lesson is that **removing a secret from the latest file does not revoke or erase a credential that has already been exposed**. A real exposed credential must be rotated or revoked; repository history and any forks, clones, logs, or caches must be considered during remediation. History rewriting is a cleanup measure, not a substitute for credential rotation.

The project README reports that TruffleHog is run in CI to detect future secret exposure. Secret scanning should be combined with least-privilege access, credential rotation, and careful handling of Terraform state.

### Vault deployment boundary

Vault is installed through a Helm release, but the project documents development mode and does not manage Vault initialization and unsealing through Terraform. A development-mode Vault deployment is not a production secrets-management architecture. Production use requires a deliberate storage, availability, recovery, authentication, authorization, and unsealing design.

## CI validation

The project documents a CI pipeline with security scanning and Terraform validation. Its stated checks are:

| Check | Purpose |
|---|---|
| TruffleHog | Searches repository history or changes for possible secrets |
| tfsec | Scans Terraform configuration for security misconfigurations |
| Checkov | Evaluates infrastructure configuration against policy checks |
| `terraform fmt -check` | Detects formatting differences |
| `terraform init` | Initializes the working directory and providers |
| `terraform validate` | Checks Terraform configuration syntax and internal consistency |

The intended sequence is security scanning followed by configuration validation. A green pipeline is evidence that the configured jobs passed for that run; it does not by itself prove that a live deployment is secure, available, or correctly configured.

## Getting started

### Prerequisites

- Terraform version `1.7.0` or later, as required by the root configuration.
- Docker and a running Minikube cluster, if following the project's local development setup.
- `kubectl` configured for the intended Kubernetes cluster.
- Network access to download the required Terraform providers and Helm charts.
- Securely supplied values for the required PostgreSQL and Grafana credentials.

### 1. Verify the Kubernetes context

The root configuration explicitly selects the `prod-sim` context for both the Kubernetes and Helm providers. Confirm that this context exists and points to the intended cluster before applying changes:

```bash
kubectl config get-contexts
kubectl config current-context
kubectl get nodes
```

Do not run `terraform apply` until the target context is correct and the cluster is reachable.

### 2. Initialize and review

Run these commands from the repository root:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
```

The project uses root-level Terraform configuration (`main.tf` and `variables.tf`) and module directories under `modules/`; therefore, do not assume there is a `terraform/` subdirectory in this repository.

### 3. Supply credentials safely

The configuration requires PostgreSQL and Grafana credential inputs. The earlier project instructions demonstrate CLI variables, but literal example passwords should not be reused. Supply unique values using your approved local secret-handling approach, and verify that any local variable file is excluded from Git before proceeding.

For example, if using a local `terraform.tfvars` file, confirm it is ignored by Git and never commit it. Review the plan for unintended changes before applying.

### 4. Apply and verify

```bash
terraform apply
kubectl get pods --all-namespaces
terraform state list
terraform plan
```

Review the plan and obtain the required approval before making changes to a shared or important environment. After applying, verify workload readiness, Service endpoints, monitoring availability, and Vault's documented development-mode constraints.

### 5. Destroy only when intended

`terraform destroy` removes resources tracked by the current Terraform state. Before using it, verify the Kubernetes context and state file, understand which resources will be removed, and ensure that no shared workloads depend on them. Do not use automatic approval flags as a substitute for reviewing the destruction plan.

## Operational limitations and next steps

The current repository documents several boundaries that should be resolved before treating the platform as production-ready:

1. **Remote state and collaboration:** adopt a secured remote backend with locking, access control, and recovery procedures before multiple operators manage the same environment.
2. **Environment separation:** define how development, test, and production configurations and state are isolated.
3. **Secret lifecycle:** ensure credentials are rotated, state is protected, and secret handling is integrated with an appropriate secret-management system.
4. **Vault lifecycle:** design and test persistent storage, initialization, unsealing, authentication, and recovery rather than relying on development mode.
5. **Complete infrastructure ownership:** decide whether cluster lifecycle, HPA, and alert rules should be brought under Terraform or managed through a clearly documented separate workflow.
6. **Automated integration checks:** verify deployed workloads and platform services after Terraform changes, not only the Terraform syntax and CI scanners.
7. **Change safety:** use reviewed plans, environment-specific approvals, and a tested recovery process for destructive changes.

These are improvement areas, not claims that the current repository already implements them.

## Documentation

The repository README links to the following supporting documents:

| Document | Purpose |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Terraform state, providers, and dependency order |
| [`docs/SECURITY.md`](docs/SECURITY.md) | Sensitive variables, credential incident, and remediation |
| [`docs/ADR.md`](docs/ADR.md) | Architecture decisions and alternatives considered |
| [`docs/INCIDENTS.md`](docs/INCIDENTS.md) | Recorded implementation incidents and lessons |
| [`docs/GAPS.md`](docs/GAPS.md) | Known gaps, including remote state and workspaces |

## Related projects

- [Auto-Healing Kubernetes Platform](https://github.com/velrite/auto-healing-k8s--) — the related platform this project builds on.
- [GitOps ArgoCD Platform](https://github.com/velrite/gitops-argocd-platform) — a related project using infrastructure-as-code patterns to provision Argo CD.
- [Forge — Internal Developer Platform](https://github.com/velrite/forge) — the documentation standard used as a reference for clear architecture, evidence-aware claims, and explicit scope boundaries.

---

**Project focus:** Terraform · Kubernetes · Helm · Infrastructure as Code · DevSecOps · Observability · Platform Engineering

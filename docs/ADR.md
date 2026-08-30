# Architecture Decision Records

---

## ADR-001 — Modules over flat configuration

**Context:**
Could write all resources in a single main.tf file.

**Decision:** Separate modules per component.

**Alternatives rejected:**
- Single flat main.tf — works for small projects. Becomes unreadable
  quickly. Cannot reuse components across projects without copy-paste.

**Trade-off accepted:**
Modules add one layer of indirection. Debugging requires navigating
between files. Worth it for the reusability and separation of concerns.

**Result:** monitoring module can be dropped into any future project.
namespaces module is generic enough to work with any namespace list.

---

## ADR-002 — Local state over remote state

**Context:**
Terraform state must be stored somewhere.

**Decision:** Local state file, excluded from Git.

**Alternatives rejected:**
- S3 remote state with DynamoDB locking — correct for production teams.
  Requires AWS account, S3 bucket creation, DynamoDB table, IAM configuration.
  Significant overhead for a single-engineer demo project.

**Trade-off accepted:**
Local state cannot be shared with a team.
State is lost if the Codespace is deleted.
Acceptable because the infrastructure can be rebuilt from `terraform apply`.

**What production would require:**
```hcl
terraform {
  backend "s3" {
    bucket         = "platform-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

---

## ADR-003 — depends_on over output-based dependencies

**Context:**
Modules need to deploy in a specific order.

**Decision:** Explicit `depends_on` blocks.

**Alternatives rejected:**
- Output-based implicit dependencies — cleaner Terraform style.
  Requires threading namespace name outputs through all downstream
  module calls. More complex variable passing for marginal elegance gain.

**Trade-off accepted:**
`depends_on` is considered less idiomatic Terraform.
It prevents Terraform from parallelizing resource creation optimally.
Explicit ordering is more readable for engineers not deep in Terraform.

---

## ADR-004 — Helm provider over raw Kubernetes manifests for tools

**Context:**
Needed to install Prometheus, Vault, OpenCost.

**Decision:** helm_release resources in Terraform.

**Alternatives rejected:**
- kubectl_manifest with raw YAML — Prometheus kube-prometheus-stack
  installs 40+ resources including CRDs. Managing this as raw manifests
  is impractical. Helm handles versioning and upgrade logic.

**Trade-off accepted:**
Helm releases are opaque to Terraform — Terraform knows a release exists
but does not manage individual pods, services, or configmaps inside it.
Plan output for Helm releases shows minimal detail compared to native resources.


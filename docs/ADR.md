# Architecture Decision Records

---

## ADR-001 — Modules over flat configuration

Context: could write all resources in single main.tf.

Decision: separate modules per component.

Alternatives rejected:
- Single flat main.tf — unreadable beyond small projects. Cannot reuse
  components without copy-paste.

Trade-off: modules add indirection. Worth it for reusability.
monitoring module works in any future project unchanged.

---

## ADR-002 — Local state over remote state

Context: Terraform state must be stored somewhere.

Decision: local state file, excluded from Git.

Alternatives rejected:
- S3 remote state with DynamoDB locking — correct for production teams.
  Requires AWS account, bucket, DynamoDB table, IAM config.
  Significant overhead for a single-engineer demo.

Trade-off: local state cannot be shared. Lost if Codespace is deleted.
Acceptable because terraform apply rebuilds everything from scratch.

---

## ADR-003 — depends_on over output-based dependencies

Context: modules need to deploy in order.

Decision: explicit depends_on blocks.

Alternatives rejected:
- Output-based implicit dependencies — cleaner Terraform style but requires
  threading namespace names through all downstream module variables.

Trade-off: depends_on is less idiomatic. Prevents parallel resource creation.
More readable for engineers not deep in Terraform.

---

## ADR-004 — Helm provider over raw manifests for tools

Context: installing Prometheus, Vault, OpenCost.

Decision: helm_release resources in Terraform.

Alternatives rejected:
- kubectl_manifest with raw YAML — Prometheus alone is 40+ resources
  including CRDs. Managing raw manifests for this is impractical.

Trade-off: Helm releases are opaque to Terraform. Plan shows minimal detail
for resources inside a Helm release.

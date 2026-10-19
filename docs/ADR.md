# Architecture Decision Records

## ADR-001: Modules per platform concern

**Context.** All 13 resources could live in one `main.tf`.
**Decision.** One module per concern: namespaces, microservices, monitoring, vault, opencost.
**Reason.** Module boundaries follow what changes together. The monitoring module can be reused in another cluster project unchanged, and namespaces can be reasoned about apart from the workloads in them.
**Trade-off.** One more layer to navigate. Plan output shows paths such as `module.monitoring.helm_release.prometheus`.
**Production view.** Keep. This is the standard way to organise Terraform at scale.

## ADR-002: Local state over remote state

**Context.** State needs a home. The production pattern is S3 with DynamoDB locking.
**Decision.** Local state, excluded from Git.
**Reason.** Remote state needs an AWS account, bucket, lock table and IAM before anything can be managed. That is heavy for a single-engineer project that is rebuilt often.
**Trade-off.** No team sharing and no locking. If the machine is lost the state is lost: the code survives, but Terraform no longer knows it owns the running resources, and apply fails with "already exists" until they are imported.
**Production view.** Replace with remote state and locking before any team uses it. See [GAPS.md](GAPS.md).

## ADR-003: Explicit depends_on between modules

**Context.** Terraform infers order from references. Modules that consume another module's outputs are ordered automatically.
**Decision.** Declare `depends_on` in the root module in addition to any output references.
**Reason.** The ordering is a real requirement, for example OpenCost needs the Prometheus from the monitoring module to exist first, and writing it explicitly makes that visible in one place.
**Trade-off.** Where an output reference already implies the order, `depends_on` is redundant. A module-level `depends_on` also makes Terraform wait for the whole upstream module, which reduces parallelism.
**Production view.** On large configurations prefer output-based dependencies for parallelism. At 13 resources the clarity is worth the cost.

## ADR-004: Helm provider over raw manifests for the three tools

**Context.** kube-prometheus-stack, Vault and OpenCost each install many objects, including CRDs.
**Decision.** One `helm_release` per tool.
**Reason.** Helm owns CRD ordering and the dependencies between dozens of objects. Expressing them as individual Terraform resources would mean tracking each in state and ordering CRDs by hand.
**Trade-off.** Helm releases are opaque to Terraform. State records the release and its values, not the objects inside. A manually deleted object inside a release does not appear in `terraform plan`; `helm status` would show it.
**Production view.** Accepted trade-off.

## ADR-005: set blocks over a values file

**Context.** Helm values can be passed as `set` blocks or a values file.
**Decision.** `set` blocks for resource limits and secrets.
**Reason.** They appear in plan output, so a changed memory limit shows as an explicit diff. A values file change shows only that a file changed.
**Trade-off.** Verbose when there are many values.
**Production view.** A hybrid: `set` for sensitive values and critical limits, a values file for large non-sensitive configuration.

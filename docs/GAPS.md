# Gaps and Technical Debt

Stated plainly, with the change production would make. Status words follow [index.md](index.md).

| Gap | Status | Risk | Production change |
| --- | ------ | ---- | ----------------- |
| Destroy then apply round trip | Not recorded | The headline claim is untested as an experiment | Run it, record timings and the resource count before and after |
| Remote state | Not built | State loss means re-importing every resource | S3 (or equivalent) backend with locking |
| Workspaces | Not built | Single environment | Separate staging and production |
| Apply from CI | Not built | Manual apply has no audit trail | Remote cluster plus a kubeconfig secret, apply after approval |
| Minikube cluster outside Terraform | Not built | The cluster is not reproducible from this repository | Manage cluster creation as code |
| HPA, alert rules, Vault configuration | Outside Terraform | Applied separately by hand | Bring under Terraform once their dependencies are stable |
| Vault in dev mode | Configured for demonstration | Data lost on restart | Real Vault with the Terraform Vault provider |
| Helm contents opaque to state | Accepted trade-off | Inner drift is invisible to plan | `helm status` checks, or a policy tool |
| Provider auth by local kubeconfig | Configured | Static local credentials | Workload identity or short-lived credentials |

## Findings read from the workflow file when these docs were generated

- tfsec and Checkov run with `soft_fail: true` in the workflow file, so they report findings but do not fail the pipeline. Only TruffleHog and the Validate stage can turn it red.
- TruffleHog runs with `--only-verified`, which reports only credentials it can confirm are live with the issuing service. A self-chosen password has nothing to verify against, so this pipeline would likely not flag the kind of secret that was leaked in Incident 1.
- Some actions in the workflow are referenced by branch (`@main`, `@master`) instead of a pinned version or commit SHA, so an upstream change alters the pipeline without a commit here.

## Remote state, the production pattern

```hcl
terraform {
  backend "s3" {
    bucket         = "<state-bucket>"
    key            = "platform/terraform.tfstate"
    region         = "<region>"
    dynamodb_table = "<lock-table>"
    encrypt        = true
  }
}
```

This is the shape of the change. It has not been applied in this project.

# Gaps and Honest Limits

---

## Remote State Not Configured

State stored locally. Breaks for teams — concurrent applies corrupt state.

Production pattern:
```hcl
backend "s3" {
  bucket         = "platform-terraform-state"
  key            = "production/terraform.tfstate"
  region         = "eu-west-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

---

## No Terraform Workspaces

Staging and production share the same state.
Production requires separate state per environment.

---

## Apply Stage Not in CI

Pipeline validates and plans but does not apply.
GitHub Actions runner does not have access to local Minikube cluster.
Apply is run manually from Codespace terminal.

What production requires:
- Remote cluster (EKS, GKE, AKS)
- Kubeconfig as GitHub Secret
- Remote Terraform state
- Approval gate before apply on main branch

---

## HPA Not Managed by Terraform

HPA lives in manifests/hpa.yaml applied separately with kubectl.
Could be kubernetes_manifest resource in Terraform but adds dependency
on metrics-server being available at plan time.

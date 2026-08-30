# Gaps and Honest Limits

---

## Remote State Not Configured

State stored locally. Correct for single engineer.
Breaks for teams — concurrent applies corrupt state.

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

Pattern for workspace separation:
```bash
terraform workspace new staging
terraform workspace new production
terraform workspace select production
terraform apply
```

---

## Apply Stage Not in CI Pipeline

GitHub Actions pipeline validates and plans but does not apply.
The runner does not have access to the local Minikube cluster.
Apply is run manually from the Codespace terminal.

What production would require:
- Remote Kubernetes cluster (EKS, GKE, AKS)
- Kubeconfig stored as GitHub Secret (base64 encoded)
- Remote Terraform state
- Environment protection rules requiring approval before apply on main

---

## HPA Not Managed by Terraform

HPA configuration lives in manifests/hpa.yaml and is applied
separately with kubectl. Not included in Terraform state.

Could be managed with kubernetes_manifest resource in Terraform.
Not done because it adds Terraform dependency on metrics-server
being available at plan time.

---

## No Terraform Tests

No automated tests validating module behavior.
Tools available for this:
- Terratest — Go-based integration testing
- terraform-compliance — BDD-style policy testing
- Checkov — already in CI for policy validation


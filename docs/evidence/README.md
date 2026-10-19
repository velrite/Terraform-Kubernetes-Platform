# Evidence Index

Each entry states what the screenshot proves, the command behind it and the result to expect. Files are named `NN-name.png` in this folder. A missing file is marked pending instead of linking a broken image.

Run the commands with credentials supplied by `terraform.tfvars` (read automatically) so that no password appears in a screenshot. Evidence 05 is a browser capture and 06 searches Git history, so check both before sharing.

| # | Evidence | File | Status |
|---|----------|------|--------|
| 01 | [Terraform state list](#01-terraform-state-list) | `01-terraform-state-list.png` | Captured |
| 02 | [Terraform plan, no changes](#02-terraform-plan-no-changes) | `02-terraform-plan-no-changes.png` | Captured |
| 03 | [Module structure](#03-module-structure) | `03-module-structure.png` | Captured |
| 04 | [Sensitive variables](#04-sensitive-variables) | `04-sensitive-variables.png` | Captured |
| 05 | [CI pipeline green](#05-ci-pipeline-green) | `05-ci-pipeline-green.png` | Captured |
| 06 | [Clean Git history](#06-clean-git-history) | `06-clean-git-history.png` | Pending |
| 07 | [Namespaces owned by Terraform](#07-terraform-namespaces) | `07-terraform-namespaces.png` | Captured |
| 08 | [Helm releases in state](#08-helm-releases-state) | `08-helm-releases-state.png` | Captured |

## 01-terraform-state-list
**Proves:** 13 resources are tracked in Terraform state

```bash
terraform state list
terraform state list | wc -l
```
**Expected result:** 13 resource addresses across the 5 modules, then the number 13

![Terraform state list](01-terraform-state-list.png)

## 02-terraform-plan-no-changes
**Proves:** The running cluster matches the code (no drift)

```bash
terraform plan
```
**Expected result:** No changes. Your infrastructure matches the configuration.

![Terraform plan, no changes](02-terraform-plan-no-changes.png)

## 03-module-structure
**Proves:** 5 modules, one platform concern each

```bash
find . -name "*.tf" -not -path "./.terraform/*" | sort
ls modules/
```
**Expected result:** namespaces, microservices, monitoring, vault, opencost, each with main.tf and variables.tf (namespaces also has outputs.tf)

![Module structure](03-module-structure.png)

## 04-sensitive-variables
**Proves:** Credential variables are typed sensitive and are not printed by plan

```bash
grep -n "sensitive" variables.tf
terraform plan 2>&1 | grep -i password
```
**Expected result:** sensitive = true on both password variables; plan output shows only variable names or (sensitive value), never a password

![Sensitive variables](04-sensitive-variables.png)

## 05-ci-pipeline-green
**Proves:** Security Scan then Validate both pass on push

```bash
GitHub, Actions tab, most recent successful run
```
**Expected result:** Security Scan (TruffleHog, tfsec, Checkov) and Validate (fmt, init, validate) both green

![CI pipeline green](05-ci-pipeline-green.png)

## 06-clean-git-history
**Proves:** The leaked password is not present in any commit

```bash
git log --oneline | head -10
git log --all -p | grep -ci "admin[1]23"
```
**Expected result:** A commit list, then 0. The pattern is written admin[1]23 so this document does not match its own search

_Screenshot pending: save it in this folder with the exact filename `06-clean-git-history.png`._

## 07-terraform-namespaces
**Proves:** Terraform created the namespaces and labelled them

```bash
kubectl get namespaces microservices monitoring vault opencost --show-labels
```
**Expected result:** 4 namespaces Active, each with managed-by=terraform and environment=production

![Namespaces owned by Terraform](07-terraform-namespaces.png)

## 08-helm-releases-state
**Proves:** Prometheus stack, Vault and OpenCost are Terraform-managed Helm releases

```bash
terraform state list | grep helm_release
terraform state show module.monitoring.helm_release.prometheus | grep -E "name|status|namespace"
```
**Expected result:** 3 helm_release addresses; prometheus shows status deployed in namespace monitoring

![Helm releases in state](08-helm-releases-state.png)

Files in `_unsorted/` are earlier captures that were in the repository root. They are not referenced by any claim.

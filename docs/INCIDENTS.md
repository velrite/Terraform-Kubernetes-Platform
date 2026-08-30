# Incidents

---

## Incident 1 — Hardcoded Password Committed to Public Repository

**What happened:**
```hcl
# main.tf — committed and pushed to GitHub
module "monitoring" {
  grafana_password = "admin123secure"
}
```

**Root cause:**
Password was written inline during initial module development
before the variable abstraction was set up. Committed without
reviewing the diff carefully.

**Fix:**
- Moved to terraform.tfvars (gitignored)
- Changed to `var.grafana_password`
- Rewrote git history with git-filter-repo
- Force pushed clean history
- Added TruffleHog to CI pipeline

**Prevention:**
Pattern enforced: variable defined with `sensitive = true` before
any resource that uses it. Never write the value anywhere except
terraform.tfvars.

---

## Incident 2 — Files Corrupted by Terminal Paste

**What happened:**
Large Terraform files pasted via terminal heredoc became corrupted:
```
EOFype = stringres_db" { {d" {/modules/microservices/variables.tf
```

`terraform init` succeeded but `terraform plan` showed 0 resources
because module files contained garbage content.

**Root cause:**
Browser-based terminals in GitHub Codespaces scramble large pastes.
Characters are dropped or interleaved when paste volume exceeds
the terminal buffer.

**Fix:**
Used VS Code editor directly for all file content:
```bash
code ~/terraform-k8s/modules/namespaces/main.tf
# Ctrl+A, delete, paste, Ctrl+S
```

**Prevention:**
Never use `cat << EOF` for files longer than 20 lines in browser terminals.
Open file in editor, paste content there instead.

---

## Incident 3 — terraform apply Showed 0 Resources Added

**What happened:**
After running terraform apply:
```
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

Expected 13 resources. Got 0.

**Root cause:**
modules/namespaces/main.tf contained the root module calls
instead of namespace resources. Files were mixed during
the corrupted paste incident (Incident 2).

**Fix:**
Opened each module file in VS Code editor.
Verified content before running apply.
Re-applied after fixing all files.

**Prevention:**
Always `cat <file>` to verify content before `terraform apply`.
Corrupted files produce no error — Terraform just has nothing to create.


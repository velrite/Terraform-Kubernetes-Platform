# Incidents

---

## Incident 1 — Hardcoded Password in Public Repository

What happened:
grafana_password = "admin123secure" committed in main.tf to public GitHub.

Root cause:
Password written inline during module development before variable
abstraction was set up. Committed without reviewing the diff.

Fix:
- Moved to terraform.tfvars
- Replaced with var.grafana_password
- git-filter-repo rewrote history
- Force pushed clean history

Prevention:
Define variable with sensitive = true before writing any resource that uses it.
Never write literal credential values in .tf files.

---

## Incident 2 — Files Corrupted by Terminal Paste

What happened:
Large Terraform files pasted via terminal heredoc became corrupted:
```
EOFype = stringres_db" { {d" {/modules/microservices/variables.tf
```
terraform plan showed 0 resources because module files had garbage content.

Root cause:
Browser terminals in GitHub Codespaces scramble large pastes.
Characters dropped or interleaved when paste exceeds terminal buffer.

Fix:
Used VS Code editor for all file content.
code filename.tf → Ctrl+A → delete → paste → Ctrl+S.

Prevention:
Never use cat << EOF for files longer than 20 lines in browser terminals.

---

## Incident 3 — terraform apply Showed 0 Resources

What happened:
After terraform apply:
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
Expected 13 resources.

Root cause:
modules/namespaces/main.tf contained root module calls instead of
namespace resources — corrupted during Incident 2.

Fix:
Opened each module file in VS Code, verified content, re-applied.

Prevention:
Always cat the file to verify content before terraform apply.
Corrupted files produce no error — Terraform just has nothing to create.

# Security

## Sensitive Variable Pattern

All credentials marked sensitive = true.
Terraform enforces they never appear in plan or apply output.

Values only in terraform.tfvars — excluded from Git:
```
# .gitignore
*.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

---

## Credential Exposure Incident

Grafana password was hardcoded in main.tf and committed to GitHub:
```hcl
grafana_password = "admin123secure"
```

Detection: manual code review.

Fix:
1. Moved value to terraform.tfvars
2. Replaced with var.grafana_password
3. Scrubbed from all history:
```bash
git filter-repo --replace-text <(echo "admin123secure==>REDACTED") --force
git push origin main --force
```

Verified clean:
```bash
git log --all -p | grep -i "admin123"
# Returns nothing
```

---

## CI Security Scanning

TruffleHog: scans every push for hardcoded secrets.
tfsec: scans Terraform for security misconfigurations. Soft fail.
Checkov: validates compliance policies. Soft fail.

Known acceptable skips documented in workflow file.
Real production would hard fail on tfsec and Checkov findings.

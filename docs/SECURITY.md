# Security

## Sensitive Variable Pattern

All credentials use `sensitive = true` in variable definitions.
Terraform enforces that sensitive values never appear in plan or apply output.

```hcl
# variables.tf
variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}
```

Values provided only in terraform.tfvars which is excluded from Git:
```
# .gitignore
*.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

---

## Credential Exposure Incident

During development, Grafana password was hardcoded in main.tf:
```hcl
grafana_password = "admin123secure"  # WRONG — never do this
```

This was committed and pushed to a public GitHub repository.

**Detection:** Manual code review during commit preparation.

**Remediation:**
1. Immediately moved value to terraform.tfvars (gitignored)
2. Replaced with `var.grafana_password`
3. Used git-filter-repo to scrub the value from all history:
   ```bash
   git filter-repo --replace-text <(echo "admin123secure==>REDACTED") --force
   git push origin main --force
   ```
4. Verified removal:
   ```bash
   git log --all -p | grep -i "admin123"
   # Returns nothing — clean
   ```

**Prevention:**
Never write literal credential values in .tf files.
Pattern: define variable first with `sensitive = true`, then reference it.
CI pipeline runs TruffleHog on every push to catch future occurrences.

---

## CI Security Scanning

**TruffleHog:** Scans every commit for hardcoded secrets.
Configured with `--only-verified` to reduce false positives.
If triggered, pipeline stops and nothing else runs.

**tfsec:** Scans Terraform configurations for security misconfigurations.
Soft fail enabled — reports findings but does not block pipeline.
Real production would enforce hard fail.

**Checkov:** Validates compliance policies against Terraform resources.
Known acceptable deviations skipped explicitly:
- CKV_K8S_28: NET_RAW capability (demo environment, not production)
- CKV_K8S_30: Security context (demo app does not require it)


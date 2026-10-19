# Security

## Sensitive variables

```hcl
variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "grafana_password" {
  type      = string
  sensitive = true
}
```

`sensitive = true` makes Terraform print `(sensitive value)` instead of the value in plan and apply output. It does **not** encrypt anything. The value is stored in plaintext in `terraform.tfstate`.

So the protection is the combination of three things:

1. the variable is typed sensitive, so it is not printed
2. the value is supplied from a gitignored `terraform.tfvars`, never written in a `.tf` file
3. `terraform.tfstate` is gitignored and treated as a secret itself

## Supplying values

Prefer `terraform.tfvars` or `TF_VAR_*` environment variables. Passing `-var="password=..."` works, but it places the secret in shell history and in the process list. `terraform.tfvars.example` holds placeholders only.

## Files excluded from Git

`*.tfvars`, `*.tfstate`, `*.tfstate.backup`, `.terraform/`, `vault-init.json`, and downloaded binaries.

## Credential exposure incident

A Grafana admin password was written inline in `main.tf` and pushed to this public repository. Full account in [INCIDENTS.md](INCIDENTS.md).

What the remediation achieved and what it did not:

- The value was removed from the working tree and replaced with a sensitive variable.
- All history was rewritten with `git-filter-repo` and force-pushed.
- A search of every commit on every branch for the old string returned no match.
- Rewriting history limits further exposure. It cannot recall copies that were already public, so the correct treatment of any credential that has been public is also to rotate it. The value was a Grafana admin password for a lab cluster that is rebuilt regularly.
- The verification search must be written so that documentation does not contain the string it searches for. This repository writes the pattern as `admin[1]23`, which matches the old value but not its own text.

## CI scanning

| Tool | Looks for | Note |
| ---- | --------- | ---- |
| TruffleHog | Secrets in commits | `--only-verified` reports only credentials it can confirm are live with the issuing service |
| tfsec | Terraform security misconfiguration | See GAPS for whether findings fail the build |
| Checkov | Policy and compliance rules | See GAPS for whether findings fail the build |

Verified-only scanning gives few false positives, but a self-chosen password such as the one leaked here has no issuing service to verify against, so this scan would likely not have flagged it. Preventing that class of mistake relies on the variable pattern and review. A pattern-based scanner such as Gitleaks would complement TruffleHog. That is planned, not built.

## Remaining exposure

- Local state holds secrets in plaintext on the machine that runs Terraform.
- Vault runs in dev mode: in-memory, auto-unsealed, for demonstration only.
- No authentication or network policy work is part of this project.

# Incidents

## Incident 1: Credential committed to a public repository

**Symptom.** During review preparation, a Grafana admin password was found written inline in `main.tf` in the public repository history.

**Root cause.** The value was typed directly into the module call while the module was being developed, before the variable pattern existed and before CI scanning was in place.

**Fix.**
1. Replaced the literal with `var.grafana_password` and moved the value to the gitignored `terraform.tfvars`.
2. Installed `git-filter-repo` and rewrote all history, replacing the old string.
3. Force-pushed the rewritten history.

**Verification.** A search of every commit on every branch for the old string returned no match. The command and its expected result are in [evidence 06](evidence/README.md#06-clean-git-history).

**Lessons.**
- Removing a value from a file does not remove it from history. History rewriting is required, and verification must search all commits.
- Rewriting history does not recall copies that were already public. Rotation is the complete response.
- Verified-only secret scanning would likely not catch a self-chosen password. The variable pattern is the actual prevention.
- Documentation must not contain the string it searches for, or the search matches its own documentation.

## Incident 2: Module files corrupted by terminal paste

**Symptom.** `terraform plan` showed 0 resources although the module files existed. Their contents were garbage, for example a line that read like `EOFype = stringres_db" { {d" {/modules/microservices/variables.tf`.

**Root cause.** Large heredoc pastes (`cat << EOF > file.tf`) into a browser-based terminal in GitHub Codespaces lose and interleave characters when the paste exceeds the terminal's buffer. The shell reported no error.

**Fix.** Wrote every file in the editor instead of the terminal: open the file, replace its contents, save.

**Verification.** Files read correctly with `cat`, and `terraform plan` listed the expected resources.

**Lesson.** Do not paste long heredocs into a browser terminal. Corruption is silent.

## Incident 3: apply succeeded and created nothing

**Symptom.** After the files were repaired, `terraform apply` printed `Apply complete! Resources: 0 added, 0 changed, 0 destroyed.` when 13 resources were expected.

**Root cause.** The repair had put the root module calls inside `modules/namespaces/main.tf` instead of the four namespace resources. Terraform parsed a valid file that declared no resources, so there was nothing to create and nothing to report as wrong.

**Fix.** Read the file with `cat`, saw the wrong content, replaced it with the namespace resource definitions in the editor and reapplied.

**Verification.** `terraform state list | wc -l` returned 13 ([evidence 01](evidence/README.md#01-terraform-state-list)).

**Lesson.** A successful apply is not proof that the right thing was applied. Check the resource count, not the exit code.

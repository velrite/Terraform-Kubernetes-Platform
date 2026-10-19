# Runbook

## Build

```bash
minikube start --profile=prod-sim
kubectl config current-context          # prod-sim
cp terraform.tfvars.example terraform.tfvars   # set real values
terraform init
terraform plan
terraform apply
```

## Verify

```bash
terraform state list | wc -l            # 13
terraform plan                          # No changes. Your infrastructure matches the configuration.
kubectl get namespaces -l managed-by=terraform
```

## Destroy

```bash
terraform destroy
```

## Before every push

```bash
terraform fmt -recursive                # CI runs fmt -check, which exits 3 on unformatted files
```

## Recover from lost state (written down, not yet exercised)

If `terraform.tfstate` is lost while the cluster still holds the resources, `terraform plan` shows everything as new and apply fails with "already exists". Import each resource into state instead:

```bash
terraform import module.namespaces.kubernetes_namespace.microservices microservices
terraform import module.microservices.kubernetes_deployment.api_service microservices/api-service
terraform import module.monitoring.helm_release.prometheus monitoring/prometheus
```

Repeat for all 13 addresses from the evidence 01 list. Namespaced objects use `namespace/name`. Adjust names if `kubectl get` shows different ones. Finish with `terraform plan` and expect no changes.

## Common failures

| Failure | Detection | Recovery |
| ------- | --------- | -------- |
| Cluster does not exist | Providers fail to connect on init or plan | Start Minikube first |
| Namespace creation fails | First apply errors, dependent modules skip | Fix the cause, reapply |
| Helm timeout | `helm_release` returns a timeout | `helm uninstall` the release, reapply |
| State corrupted | Plan returns a parse error | Restore the backup, or import |
| Provider version conflict | `terraform init` fails on constraints | Adjust the constraint |
| Apply reports 0 resources | `Resources: 0 added` | `cat` the module files, see Incident 3 |

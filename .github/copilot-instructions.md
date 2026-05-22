# Copilot Instructions for `aks-enterprise-demo`

## Build, test, and lint commands

This repo is Terraform-only (no compiled build step and no automated Terraform test suite configured).

Use these commands from the repository root:

```bash
# Format check (lint-style)
terraform fmt -check -recursive

# Validate root module
terraform init -backend=false
terraform validate

# Validate an environment plan shape
terraform plan -var-file=envs/dev.tfvars

# Reference lint command used in docs/CI pattern (if installed)
tflint --recursive
```

Single-scope validation (closest equivalent to a single test):

```bash
cd modules/private_aks
terraform init -backend=false
terraform validate
```

## High-level architecture

- Root `main.tf` orchestrates a **hub-and-spoke private AKS baseline**: `hub_network`, `spoke_network`, `private_dns_zones`, and `private_aks`.
- Two resource groups are created per environment: `rg-paks-<env>-hub` and `rg-paks-<env>-spoke`.
- The active graph is dependency-driven by module outputs (VNet/subnet IDs, DNS zone IDs), with an explicit root `depends_on` only where Azure creation order is strict (`private_aks` waits for DNS zone setup).
- `private_aks` uses a user-assigned identity, private API endpoint, BYO private DNS zone, and UDR outbound mode.
- `envs/dev.tfvars`, `envs/test.tfvars`, and `envs/prod.tfvars` are the environment entry points (network ranges, AKS sizing, retention, tags).
- Several modules exist but are currently not wired in active `main.tf` (firewall/bastion/jumpboxes/ACR/monitoring/node-pools). `main.tf.backup` documents the fuller intended composition.

## Key conventions in this codebase

- **Version pinning is strict and duplicated at root + every module**: Terraform `>= 1.5.0`, `azurerm ~> 4.0`.
- **Module shape is uniform**: each module keeps `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf`.
- **Naming convention is centralized**: `local.name_suffix = "paks-${var.environment}"` and reused for all resource names.
- **`unique_identifier` is required for globally-unique names** and validated as 1-6 lowercase alphanumeric characters.
- **Secrets are never stored in `envs/*.tfvars`**; set sensitive values through `TF_VAR_*` environment variables (jumpbox passwords and optional operator override).
- **Operator identity fallback is automatic**: if `operator_object_id` is empty, code uses the currently authenticated Azure principal (`data.azurerm_client_config.current.object_id`).
- **Tagging pattern**: root merges `var.tags` with `{ environment = var.environment }` and passes merged tags to all modules.
- **Dependency style**: prefer implicit dependencies through input/output wiring; add explicit `depends_on` only for known Azure ordering requirements.

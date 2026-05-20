# Demo 03 — Remote State Backend (Azure Storage)

## Why this matters in the enterprise

Local state (`terraform.tfstate`) is fine for learning, but it is dangerous in real teams:

- It cannot be shared safely.
- It has **no locking**, so two engineers running `apply` simultaneously can corrupt state.
- It risks leaking secrets stored in state to laptops/git.

Enterprises move state to a **remote backend**. On Azure, the most common pattern
is an **Azure Storage Account container** with:

- Versioning / soft delete enabled (recover from bad applies)
- Encryption at rest with a customer-managed key (CMK) where required
- Locked down with RBAC and (often) private endpoints
- Locking via Azure Storage blob leases (built into `azurerm` backend)

This demo **bootstraps** that backend with local state, then teaches you how to
migrate other configurations to use it.

## What this demo creates

- A resource group for shared platform infrastructure (`rg-tfstate-<env>`)
- A storage account with:
  - HTTPS only, TLS 1.2 minimum
  - Public blob access disabled
  - Blob versioning + 30 day soft delete
  - Infrastructure encryption enabled
- A container named `tfstate`

## Usage

```bash
cd demos/03-remote-state-backend
terraform init
terraform apply -var "environment=dev" -var "location=eastus"
```

After it applies, copy the outputs and use them in **other** configurations:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "<the storage_account_name output>"
    container_name       = "tfstate"
    key                  = "myproject/dev.tfstate"
  }
}
```

Then `terraform init -migrate-state` in that configuration will move local state
to Azure.

## Enterprise patterns illustrated here

1. **Bootstrap problem**: the backend itself must be created with local state, then
   imported / migrated to itself if you want it self-managed. This demo intentionally
   keeps the bootstrap in local state and recommends a separate "platform" repo or
   pipeline that owns it.
2. **State key naming convention**: `<project>/<env>.tfstate` enables one storage
   account to host many workloads while keeping blast radius small.
3. **Per-environment isolation**: one container per environment (or one key per env)
   keeps blast radius small and aligns with least-privilege RBAC.
4. **Recovery**: enabling soft delete + versioning is non-negotiable for production
   state.

# terraform-azure

Learning Terraform concepts with Azure through small hands-on demos.

## What you will learn

- Terraform workflow (`init`, `plan`, `apply`, `destroy`)
- Providers, variables, outputs, and local values
- Reusable naming patterns
- Resource dependencies in Azure
- Practical best practices for Terraform on Azure

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- Azure CLI (`az`) installed and logged in:

```bash
az login
```

## Demo structure

- `demos/01-resource-group` - basic provider setup, variables, and an Azure resource group
- `demos/02-storage-account` - adds a storage account with naming rules and dependencies

## Run a demo

```bash
cd demos/01-resource-group
terraform init
terraform plan -var "resource_group_name=rg-tf-demo-dev" -var "location=eastus"
terraform apply -var "resource_group_name=rg-tf-demo-dev" -var "location=eastus"
terraform destroy -var "resource_group_name=rg-tf-demo-dev" -var "location=eastus"
```

For demo 2, use the same commands in `demos/02-storage-account`.

## Best practices when using Terraform with Azure

1. **Use remote state** for team workflows (Azure Storage backend + state locking where available).
2. **Pin provider and Terraform versions** to avoid unexpected breaking changes.
3. **Use variables and validation** to avoid invalid Azure naming/region inputs.
4. **Keep modules small and focused** (network, identity, compute, etc.).
5. **Never commit secrets**; use environment variables, Azure Key Vault, or CI secret stores.
6. **Tag resources consistently** for ownership, environment, and cost reporting.
7. **Use separate state/workspaces per environment** (`dev`, `test`, `prod`) rather than one shared state.
8. **Review `terraform plan` carefully** before every apply, especially in production.
9. **Run `terraform fmt` and `terraform validate`** in local checks/CI.
10. **Prefer managed identity/RBAC** over embedded credentials.

## Suggested learning order

1. Start with demo 1 to understand Terraform fundamentals with Azure.
2. Continue with demo 2 to understand dependencies and naming constraints.
3. Add your own module folder and split reusable logic as your next exercise.

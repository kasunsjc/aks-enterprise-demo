# terraform-azure

A hands-on learning repository that progresses from **Terraform basics** to
**enterprise-grade scenarios** on Azure. Each demo is self-contained and
explains both the *what* and the *why*.

## Demo progression

| #   | Demo                                                  | Concepts                                                                                   |
| --- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| 01  | [`demos/01-resource-group`](demos/01-resource-group)             | Providers, variables, outputs, tagging                                                     |
| 02  | [`demos/02-storage-account`](demos/02-storage-account)           | Dependencies, naming constraints, validation, `random_string`                              |
| 03  | [`demos/03-remote-state-backend`](demos/03-remote-state-backend) | Remote state on Azure Storage, versioning, soft delete, bootstrap pattern                  |
| 04  | [`demos/04-modules-hub-spoke`](demos/04-modules-hub-spoke)       | Reusable modules, `for_each` over a map, hub-and-spoke VNet topology, bidirectional peering |
| 05  | [`demos/05-multi-environment`](demos/05-multi-environment)       | Per-environment root modules with a shared module, dev vs prod sizing & tags               |
| 06  | [`demos/06-aks-keyvault`](demos/06-aks-keyvault)                 | AKS with managed identity, Workload Identity (OIDC), Key Vault (RBAC), Log Analytics       |
| 07  | [`demos/07-secure-webapp-sql`](demos/07-secure-webapp-sql)       | Private endpoints, Private DNS Zones, App Service VNet integration, Key Vault references   |
| 08  | [`demos/08-private-aks-hub-spoke`](demos/08-private-aks-hub-spoke) | Private AKS in hub-and-spoke, Azure Firewall (egress lockdown), Bastion + jumpbox, private ACR, BYO Private DNS for the API |

## Deep-dive documents

- [`docs/enterprise-concepts.md`](docs/enterprise-concepts.md) — state strategy,
  module tiers, environments, identity, policy-as-code, drift, import, day-2 fires,
  naming/tagging, recommended repo layout.
- [`docs/ci-cd-pipeline.md`](docs/ci-cd-pipeline.md) — reference GitHub Actions
  pipeline using Azure OIDC, with plan-as-PR-comment and gated production apply.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- Azure CLI — log in once before running anything:

  ```bash
  az login
  az account set --subscription "<your subscription id>"
  ```

## Suggested learning path

1. **Demos 01–02** — get the muscle memory of `init / plan / apply / destroy`,
   variables, outputs, and basic Azure resource constraints.
2. **Demo 03** — set up remote state. Every subsequent enterprise pattern depends on this.
3. **Demo 04** — learn modules and `for_each`. Hub-and-spoke is the canonical
   landing-zone topology.
4. **Demo 05** — split into environments. Understand isolation and promotion.
5. **Demo 06** — wire up a production-style AKS with Workload Identity, Key Vault, and observability.
6. **Demo 07** — apply private networking + secret-handling patterns to a 3-tier app.
7. **Demo 08** — graduate to a fully private AKS landing zone with Firewall egress lockdown, Bastion-only access, and private ACR.
8. Read **`docs/enterprise-concepts.md`** and **`docs/ci-cd-pipeline.md`** for
   the surrounding operating model.

## Best practices summary

The full list lives in [`docs/enterprise-concepts.md`](docs/enterprise-concepts.md);
here is the short version:

1. **Remote state on Azure Storage**, with versioning + soft delete + RBAC.
2. **One state file per environment per workload** — small blast radius.
3. **Pin Terraform and provider versions** (`required_version`, `~>` constraints).
4. **Treat modules as APIs** — typed inputs, validation, structured outputs, versioned.
5. **No service-principal secrets in CI** — use OIDC federated credentials.
6. **No secrets in code or outputs** — use `random_password`, Key Vault, and
   App Service / Workload Identity references.
7. **Defense-in-depth**: `terraform fmt`/`validate`, `tflint`, `tfsec`/`checkov`,
   OPA/Sentinel on plan, plus Azure Policy at runtime.
8. **Plan before apply**, always. PR-comment the plan for reviewers.
9. **Gate production** behind manual approvals; never auto-apply to prod.
10. **Detect drift** with scheduled `terraform plan` and alerts.
11. **Adopt existing resources** via `import {}` blocks, never by editing state by hand.
12. **Tag consistently** (`environment`, `owner`, `cost_center`, `managed_by`) and
    enforce via Azure Policy.

## How to run any demo

```bash
cd demos/<demo-folder>
terraform init
terraform plan
terraform apply
# ...and when you're done:
terraform destroy
```

> ⚠️ Some demos (06, 07, 08) provision paid Azure resources (AKS, App Service Plan,
> SQL DB, Azure Firewall, Bastion, etc.). Always `terraform destroy` after
> experimenting to avoid ongoing charges.

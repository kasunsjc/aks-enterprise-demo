# Enterprise Terraform + Azure: Concepts You Need to Know

This document is the "what they don't teach you in the basics" guide. It explains
the scenarios enterprise teams actually run into when using Terraform with Azure
and how to handle them.

---

## 1. State management

### 1.1 Remote state on Azure

Production teams **never** use local state. They use the `azurerm` backend on
top of an Azure Storage account with:

- Blob versioning enabled (rollback to a known-good state)
- 30-day soft delete (recover from accidental destroy)
- Public network access locked down or replaced with a private endpoint
- RBAC-controlled access — granular per environment / per project

See `demos/03-remote-state-backend` for a reference implementation.

### 1.2 State file layout

A common, scalable layout uses **one state file per environment per workload**:

```
tfstate/
└── tfstate/                     # container
    ├── platform/
    │   ├── dev.tfstate
    │   └── prod.tfstate
    ├── networking/
    │   ├── dev.tfstate
    │   └── prod.tfstate
    └── orders-api/
        ├── dev.tfstate
        └── prod.tfstate
```

Goals: **small blast radius**, **independent apply cadence**, **least-privilege**
RBAC per state file.

### 1.3 Locking

The `azurerm` backend uses blob leases for locking automatically. Always confirm
you see "Acquiring state lock" in CI logs — it means concurrent applies are
prevented.

---

## 2. Module strategy

Treat modules like internal APIs:

| Tier            | Lives in              | Versioned?            | Reusable across teams? |
| --------------- | --------------------- | --------------------- | ---------------------- |
| **Inline** module    | Same repo as caller   | No                    | No                     |
| **Repo-local** module| `modules/` folder     | Pinned by commit/path | Within one repo        |
| **Published** module | Private/public registry | Semver tags           | Yes                    |

Enterprises typically build a small set of golden modules (network, AKS,
storage, web app) and require teams to use them. Demo 04 shows the structure of
repo-local modules.

### Module design rules

- Inputs use `type =` constraints **and** `validation {}` blocks.
- Outputs expose IDs and names, not whole resource objects.
- Each module includes a `versions.tf` pinning `required_version` and
  `required_providers`.
- Modules should be **composable**, not feature-flag-heavy. Two small modules
  beat one giant one with 30 booleans.

---

## 3. Environments and promotion

Three popular approaches:

1. **Directory per environment** (`envs/dev`, `envs/prod`) — most common in
   regulated enterprises. Strong isolation; each env has its own state and
   pipeline. See `demos/05-multi-environment`.
2. **Workspaces** — `terraform workspace select prod`. Acceptable for small
   teams or short-lived environments (per-PR review apps). Use carefully — the
   code path is identical for dev and prod.
3. **Terragrunt / wrappers** — a DRY layer on top of Terraform that some
   organizations adopt.

### Promotion flow

A common CI/CD model:

```
PR opened → terraform fmt/validate/tflint/checkov → plan against dev
PR merged → apply to dev (auto)
Tag created → apply to stage (manual approval)
Release approved → apply to prod (change advisory board / manual gate)
```

---

## 4. Identity and secret handling

### 4.1 No service principals when avoidable

Prefer **managed identities** for CI/CD via:

- GitHub Actions: **OIDC** federated credentials to an Azure AD app registration.
- Azure DevOps: **Workload Identity Federation** service connections.

You get **no client secrets in CI** and short-lived tokens.

### 4.2 Secrets in state

The Terraform state file contains the **plain-text values** of resources
including generated passwords. Therefore:

- Never store the state in a public location.
- Restrict who can read the storage container.
- Treat the state file as a secret artifact (audit reads when possible).

### 4.3 Secrets in code

- Use `random_password` for generated values.
- Mark sensitive outputs with `sensitive = true`.
- Pass secrets to apps via **Key Vault references** in App Service, AKS Workload
  Identity, or `azurerm_key_vault_secret` consumed at runtime — not via
  Terraform-rendered values.

Demo 07 illustrates this end-to-end.

---

## 5. Policy as Code

Defense in depth at three layers:

| Layer       | Tool                                                         | Catches                                          |
| ----------- | ------------------------------------------------------------ | ------------------------------------------------ |
| Code        | `terraform fmt`, `terraform validate`, `tflint`, `tfsec`, `checkov`, `Trivy` | Formatting, syntax, common security misconfigs   |
| Plan        | `conftest` / OPA, `infracost`, `Sentinel`                    | Policy violations and cost blowups               |
| Cloud       | **Azure Policy** assignments                                 | Drift, enforcement of org standards at runtime   |

A robust setup runs static checks in PR (block merge if they fail), policy
checks on `terraform plan`, and Azure Policy at the platform level.

---

## 6. Drift detection

Drift = the real cloud state diverges from what Terraform thinks it is. Causes:

- A teammate clicked in the portal.
- An auto-remediation tool changed a setting.
- Azure Policy enforced a change after the fact.

Detect drift by scheduling `terraform plan` (no apply) on a cron in CI and
**alerting** when the plan is non-empty. For very large estates, tools like
`driftctl` help.

When drift is found:

1. **Investigate** before reverting — drift can hide a manual hotfix.
2. Either update Terraform to match the cloud (preferred when the change is
   correct) or re-apply to restore the desired state.

---

## 7. Importing existing resources

Most enterprises have resources that pre-date Terraform. You can adopt them:

- Modern: **`import { }` blocks** in code (Terraform >= 1.5). Reviewable in PR.
- Classic: `terraform import <addr> <id>` (mutates state only).

Pattern:

1. Write the resource HCL.
2. Add an `import` block with the address and the Azure resource ID.
3. `terraform plan` should show "import" + 0 changes (or only attribute drift).
4. After successful apply, remove the `import` block.

---

## 8. Common day-to-day "fires"

| Problem                                                  | What to do                                                                |
| -------------------------------------------------------- | ------------------------------------------------------------------------- |
| `apply` fails halfway, resources orphaned                | Re-run `apply`; Terraform refreshes and continues. Don't manually fix in the portal. |
| Resource needs to be replaced but downtime is unacceptable | Use `create_before_destroy = true` lifecycle, or split via blue/green.    |
| Provider upgrade breaks plan                             | Pin versions, upgrade one at a time, use `terraform plan -refresh-only`.  |
| Need to move a resource between modules                  | Use a `moved {}` block (Terraform >= 1.1).                                |
| Apply got stuck holding the lock                         | Investigate first; only as last resort `terraform force-unlock <id>`.     |
| State corrupted / wrong                                  | Restore the previous **blob version** from Azure Storage.                 |

---

## 9. Naming and tagging

Pick a convention, enforce with Azure Policy. Example:

- `<type>-<workload>-<env>-<region>-<instance>` → `vnet-orders-prod-eastus-01`
- Mandatory tags: `environment`, `owner`, `cost_center`, `workload`, `managed_by=terraform`.

Use `default_tags` (provider-level) where possible, and merge with per-resource
tags via `merge(local.tags, { ... })`.

---

## 10. Recommended folder structure for a real repo

```
terraform-azure/
├── modules/                # reusable modules (network, aks, sql, etc.)
├── envs/
│   ├── dev/
│   ├── stage/
│   └── prod/
├── platform/               # state backend bootstrap, identity, policies
├── docs/
└── .github/workflows/      # CI: fmt, validate, tflint, checkov, plan, apply
```

The demos in this repo mirror parts of this layout incrementally so you can
learn the moving pieces.

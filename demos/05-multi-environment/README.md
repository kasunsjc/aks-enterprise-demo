# Demo 05 — Multi-Environment Configuration (dev / prod)

Enterprises rarely deploy only to one environment. The two most common
strategies for managing `dev`, `stage`, `prod` with Terraform are:

| Strategy                      | What it is                                                          | Pros                                       | Cons                                                |
| ----------------------------- | ------------------------------------------------------------------- | ------------------------------------------ | --------------------------------------------------- |
| **Per-env directory** (this demo) | `envs/dev`, `envs/prod` each is its own root module                 | Strong isolation, different versions/state | Some duplication; mitigated with shared modules     |
| **Workspaces**                | One root module, `terraform workspace new prod`                     | Less duplication                           | Same code path for all envs (risky for blast radius)|
| **Tfvars only**               | One root, `terraform apply -var-file=prod.tfvars`                   | Simple                                     | Single state shared across envs (very risky)        |

> Most enterprise teams pick **per-env directory** for production workloads
> because each environment gets its own state, RBAC, and approval workflow.

This demo shows the per-env approach plus a **shared module** (`modules/app`)
so the actual resources are defined once.

## Layout

```
demos/05-multi-environment/
├── modules/
│   └── app/        # the workload definition (used by every env)
└── envs/
    ├── dev/        # cheaper SKUs, public network access allowed
    └── prod/       # production SKUs, redundancy, stricter defaults
```

## Concepts taught

- Environment isolation via separate root modules and separate state files
- Sharing logic via local modules (`source = "../../modules/app"`)
- Differentiating environments through input values (SKU, capacity, redundancy)
- Setting different `tags` and naming per environment
- Using `terraform.tfvars` per environment (vs CLI flags)

## Usage

```bash
# Dev
cd demos/05-multi-environment/envs/dev
terraform init
terraform apply

# Prod
cd ../prod
terraform init
terraform apply
```

In real life:

- `init` would point to **different backend state keys** per env.
- The Azure subscription / service principal for `prod` should be different
  from `dev` (separate identities, RBAC, even tenants if regulated).
- Production changes should be gated by **PR review + manual approval** in CI.

# CI/CD for Terraform on Azure (Reference Pipeline)

This document outlines a realistic GitHub Actions pipeline pattern for Terraform
on Azure. You can adapt the same pattern for Azure DevOps Pipelines.

## Goals

- **No long-lived secrets** — use OIDC federated credentials.
- **Fail fast** on style, lint, security, and policy issues in PR.
- **Plan as PR comment** so reviewers see the actual change.
- **Manual approval** before apply to production.
- **Per-environment state** via separate backend keys.

## Stages

```
       ┌─────────────────────────────────────────────┐
PR →   │  fmt → validate → tflint → tfsec/checkov →  │
       │  plan (dev) → comment plan on PR            │
       └─────────────────────────────────────────────┘
                              │ merge
                              ▼
       ┌─────────────────────────────────────────────┐
       │  apply (dev) auto                            │
       └─────────────────────────────────────────────┘
                              │ tag/release
                              ▼
       ┌─────────────────────────────────────────────┐
       │  plan (stage) → manual approval → apply     │
       └─────────────────────────────────────────────┘
                              │ release-approved
                              ▼
       ┌─────────────────────────────────────────────┐
       │  plan (prod) → CAB / manual approval → apply │
       └─────────────────────────────────────────────┘
```

## Example: GitHub Actions skeleton

> Not committed as a workflow file here — these demos are for learning, not
> for being executed by CI in this repo. Adapt and place in your own repo's
> `.github/workflows/`.

```yaml
name: terraform

on:
  pull_request:
  push:
    branches: [main]
    tags: ['v*']

permissions:
  id-token: write   # required for Azure OIDC
  contents: read
  pull-requests: write

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0
      - run: terraform fmt -check -recursive
      - run: terraform -chdir=envs/dev init -backend=false
      - run: terraform -chdir=envs/dev validate
      - uses: terraform-linters/setup-tflint@v4
      - run: tflint --recursive
      - uses: aquasecurity/tfsec-action@v1.0.3

  plan-dev:
    needs: validate
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - uses: hashicorp/setup-terraform@v3
      - run: terraform -chdir=envs/dev init
      - run: terraform -chdir=envs/dev plan -out=tfplan
      # Use a community action to post the plan as a PR comment.

  apply-dev:
    needs: validate
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: dev # GitHub Environment for protection rules
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - uses: hashicorp/setup-terraform@v3
      - run: terraform -chdir=envs/dev init
      - run: terraform -chdir=envs/dev apply -auto-approve
```

## Recommended add-ons

- **infracost** for cost estimation on PR.
- **checkov** for security & compliance scanning of HCL.
- **conftest** / OPA for custom org policies on the plan JSON.
- **terraform-docs** to auto-generate module documentation.
- A scheduled "drift check" workflow that runs `terraform plan` daily and
  alerts on any non-empty diff.

## Branching model

A common pattern:

- `main` is always the source of truth for `dev`.
- Promotion to higher environments is by git **tag** (or by long-lived
  environment branches in stricter shops).
- Hotfixes go through the same pipeline, never directly into prod.

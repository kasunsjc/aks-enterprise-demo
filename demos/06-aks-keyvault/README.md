# Demo 06 — AKS, Key Vault, Log Analytics (Production-Style)

This demo creates a realistic, production-leaning AKS footprint that teams
deploy every day:

- An **AKS cluster** with:
  - System-assigned managed identity
  - Azure AD integration with Azure RBAC for cluster authz
  - Workload Identity + OIDC issuer enabled (modern pattern, no SP secrets)
  - Auto-scaling node pool
  - Diagnostic settings shipping logs to Log Analytics
  - Network plugin = Azure CNI with overlay
- A **Key Vault** with RBAC authorization (not legacy access policies)
- A **Log Analytics workspace** wired into AKS

## Concepts taught

- `data` sources (`azurerm_client_config`) to look up the current tenant.
- `azurerm_role_assignment` to wire managed identities into RBAC.
- Provider/feature blocks tuned for production (`purge_soft_delete_on_destroy = false`
  for Key Vault).
- Splitting a large config into purpose-specific files (`aks.tf`,
  `keyvault.tf`, `monitor.tf`).
- Output composition for downstream pipelines (kubeconfig, vault URI).

## Enterprise-grade choices

| Choice                                  | Why                                                          |
| --------------------------------------- | ------------------------------------------------------------ |
| Managed identity instead of service principal | No client secrets to rotate or leak                          |
| Workload Identity (OIDC)                | Lets pods get Entra tokens without storing secrets in cluster |
| Key Vault RBAC                          | Single source of truth (RBAC), auditable, supports JIT       |
| Soft delete / purge protection enabled  | Protects secrets from accidental destruction                 |
| Diagnostic settings -> Log Analytics    | Required for any production cluster                          |
| Auto-scaling node pool                  | Cost + reliability                                           |

## Usage

```bash
cd demos/06-aks-keyvault
terraform init
terraform apply \
  -var "environment=dev" \
  -var "location=eastus" \
  -var "kubernetes_version=1.30"
```

## Things to extend in a real workload

- Add a **private cluster** (`private_cluster_enabled = true`) and Private DNS Zone.
- Add **Azure Policy add-on** + Defender for Containers.
- Place AKS into a spoke VNet from demo 04.
- Configure **App Routing** or NGINX Ingress with cert-manager.
- Use a **user-assigned managed identity** for the cluster instead of system-assigned,
  so you can pre-grant network roles.

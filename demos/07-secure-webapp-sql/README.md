# Demo 07 — Secure Web App + Azure SQL with Private Endpoints

A typical enterprise three-tier scenario:

```
   Internet
      │
      ▼
 ┌───────────────┐    VNet integration     ┌────────────────────┐
 │ Linux Web App │ ─────────────────────▶ │ Subnet (app)        │
 └───────────────┘                          └────────┬───────────┘
        │                                            │
        │ uses managed identity to read              │
        ▼                                            ▼
 ┌───────────────┐                          ┌────────────────────┐
 │ Key Vault     │◀────RBAC───              │ Private Endpoint   │
 │ (secrets)     │                          │   for Azure SQL    │
 └───────────────┘                          └────────┬───────────┘
                                                     │ private IP
                                                     ▼
                                            ┌────────────────────┐
                                            │ Azure SQL Database │
                                            │  public access off │
                                            └────────────────────┘
```

This demo demonstrates:

- **Networking lockdown**: SQL server has `public_network_access_enabled = false`
  and is reachable only through a **private endpoint** with a Private DNS Zone.
- **Identity, not passwords**: Web App uses a **System-Assigned managed identity**;
  the app gets Key Vault secrets via Key Vault references (`@Microsoft.KeyVault(...)`)
  in app settings — **no plain secrets in code or state output**.
- **Encryption / TLS**: HTTPS-only, TLS 1.2 minimum, FTPS disabled.
- **Defense in depth**: SQL admin password is generated via `random_password`,
  stored in Key Vault, never echoed in outputs.

## Concepts taught

- `random_password` + `sensitive = true` outputs.
- `azurerm_private_dns_zone` + `azurerm_private_dns_zone_virtual_network_link`.
- `azurerm_private_endpoint` with `private_dns_zone_group`.
- Key Vault references in App Service settings.
- Producing a connection string that the app reads from Key Vault, not Terraform.

## Usage

```bash
cd demos/07-secure-webapp-sql
terraform init
terraform apply -var "environment=dev" -var "location=eastus" -var "admin_object_id=<your AAD object ID>"
```

You can get your AAD object ID with:

```bash
az ad signed-in-user show --query id -o tsv
```

## What this teaches that "basic" demos do not

- The reality of stitching together identity, networking, and secret stores.
- Why production Azure resources need **multiple** dependent resources (PE + DNS
  zone + VNet link + zone group) per "one" service.
- How to avoid the temptation of dumping secrets into outputs or environment
  variables — instead use App Service Key Vault references.

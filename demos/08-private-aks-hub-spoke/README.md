# Demo 08 — Private AKS in a Hub-and-Spoke Landing Zone

End-to-end, **everything-private** AKS scenario that enterprises run in regulated
or security-sensitive workloads. There are **no public IPs on AKS, ACR, or the
jumpbox**. Operators reach the cluster through Azure Bastion → a jumpbox → the
private AKS API endpoint. All outbound traffic from the cluster is forced
through **Azure Firewall** in the hub.

## Architecture

```
                 ┌──────────────────────────── Hub VNet (10.0.0.0/16) ────────────────────────────┐
                 │                                                                                  │
   Operator ──▶  │ ┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐ │
   (browser)     │ │ AzureBastionSubnet   │    │ AzureFirewallSubnet  │    │ snet-shared          │ │
                 │ │  Azure Bastion       │    │  Azure Firewall      │    │  (future shared svc) │ │
                 │ └──────────┬───────────┘    └──────────┬───────────┘    └──────────────────────┘ │
                 │            │                            │                                          │
                 └────────────┼────────────────────────────┼──────────────────────────────────────────┘
                              │ peering                    │ DNAT not needed (no public ingress)
                              ▼                            │
                 ┌──────────────────────────── Spoke VNet (10.10.0.0/16) ──────────────────────────┐
                 │                                                                                  │
                 │ ┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐ │
                 │ │ snet-jumpbox         │    │ snet-aks             │    │ snet-pe              │ │
                 │ │   Linux VM (NIC only)│    │   AKS nodes          │    │   PE for ACR         │ │
                 │ │                       │    │   UDR → Firewall     │    │                       │ │
                 │ └──────────┬───────────┘    └─────────┬────────────┘    └──────────┬───────────┘ │
                 │            │ kubectl over             │ 0.0.0.0/0 → FW             │ private IP   │
                 │            │ private API IP           │ allowed FQDNs/ports         │              │
                 │            ▼                          ▼                              ▼              │
                 │  ┌────────────────────────────────────────────────────────────────────────────┐  │
                 │  │  Private DNS Zones linked to the spoke VNet:                               │  │
                 │  │  • privatelink.<region>.azmk8s.io  → resolves AKS private API endpoint     │  │
                 │  │  • privatelink.azurecr.io          → resolves ACR private endpoint          │  │
                 │  └────────────────────────────────────────────────────────────────────────────┘  │
                 └──────────────────────────────────────────────────────────────────────────────────┘
```

## What this demo provisions

| Component | Purpose |
|---|---|
| Hub VNet + 3 subnets | Shared services + Bastion + Firewall |
| Spoke VNet + 3 subnets | AKS nodes, private endpoints, jumpbox |
| VNet peerings (bidirectional) | Hub ↔ spoke routing |
| **Azure Firewall (Standard)** + Firewall Policy | Egress control for the cluster |
| Firewall application + network rule collections | Allow only the FQDNs/ports AKS needs |
| Route table on `snet-aks` | UDR: `0.0.0.0/0` → Firewall private IP |
| **Azure Bastion (Standard SKU)** | Browser-based SSH to jumpbox; no public IPs on the VM |
| Private DNS Zones (`privatelink.<region>.azmk8s.io`, `privatelink.azurecr.io`) | Required for private cluster + private ACR name resolution |
| **Private AKS cluster** (`private_cluster_enabled = true`, BYO private DNS zone) | API server has a **private** IP only |
| User-assigned managed identity for AKS | Pre-grant Private DNS Zone Contributor + Network Contributor on spoke |
| **Premium ACR** with `public_network_access_enabled = false` and **private endpoint** | All image pulls flow over private network |
| `AcrPull` role assignment on ACR for AKS kubelet identity | Pulling images without secrets |
| Linux jumpbox VM | Reach the private API server via Bastion |

## Why each piece is needed in an enterprise

- **Private cluster** removes the public API endpoint — required by many
  compliance baselines (PCI, HIPAA, internal banking standards).
- **BYO private DNS zone** lets multiple spokes resolve the API name and lets
  Terraform manage the zone (auditable, versioned).
- **User-assigned MI for AKS** is mandatory when using a BYO private DNS zone —
  AKS needs `Private DNS Zone Contributor` on the zone **before** cluster create.
- **Azure Firewall + UDR** centralizes egress so security teams audit one place.
  AKS has a published list of required FQDNs and ports — this demo encodes them
  in a firewall policy.
- **Private ACR** prevents image exfiltration / public pull-through. AKS
  requires `AcrPull` on the registry and resolves it via the
  `privatelink.azurecr.io` zone.
- **Bastion + jumpbox** is the standard "operators only" path. Engineers never
  carry public IPs or open NSG ports.

## Outbound rules implemented

AKS [requires](https://learn.microsoft.com/azure/aks/limit-egress-traffic)
specific egress. This demo encodes a minimal subset in the firewall policy:

**Network rules**
- TCP/9000 to `AzureCloud.<region>` (tunnel front-end)
- UDP/1194 to `AzureCloud.<region>` (legacy tunnel)
- UDP/123 to `*` for NTP
- TCP/443 to `AzureCloud.<region>`, `AzureMonitor`, `MicrosoftContainerRegistry`

**Application rules (HTTPS)**
- `*.hcp.<region>.azmk8s.io`, `*.tun.<region>.azmk8s.io`
- `mcr.microsoft.com`, `*.data.mcr.microsoft.com`, `*.cdn.mscr.io`
- `management.azure.com`, `login.microsoftonline.com`
- `packages.microsoft.com`, `acs-mirror.azureedge.net`
- `*.ods.opinsights.azure.com`, `*.oms.opinsights.azure.com`, `*.monitoring.azure.com`

> The list is intentionally a starting point. For your environment also enable
> the [Microsoft FQDN tag](https://learn.microsoft.com/azure/firewall/fqdn-tags)
> `AzureKubernetesService` (single line in firewall policy) — this demo enables
> it on the application rule collection.

## Usage

```bash
cd demos/08-private-aks-hub-spoke
terraform init
terraform apply \
  -var "environment=dev" \
  -var "location=eastus" \
  -var "jumpbox_admin_username=azureadmin" \
  -var "jumpbox_admin_password=<a-strong-password-or-use-ssh>" \
  -var "operator_object_id=$(az ad signed-in-user show --query id -o tsv)"
```

> ⚠️ This demo provisions **paid Azure resources that are expensive when
> idle** — Azure Firewall (~$900/mo when running), Bastion (~$140/mo), AKS
> control plane, Premium ACR, VMs, public IPs. Always `terraform destroy`
> after experimenting.

### Connecting to the cluster

1. In the Azure portal, navigate to the jumpbox VM → **Connect → Bastion**.
2. Log in with the username/password (or SSH key) you provided.
3. On the jumpbox:

   ```bash
   az login
   az aks get-credentials -g rg-paks-<env> -n aks-paks-<env>
   kubectl get nodes
   ```

   The `kubectl` API call resolves the private API FQDN to a **private IP**
   (10.10.x.x) via the private DNS zone linked to the spoke VNet.

## Concepts taught (beyond demo 06)

- **Private cluster** wiring with a **BYO Private DNS Zone** (not just
  `system`-managed).
- **User-assigned managed identity** for AKS, with **pre-applied RBAC** before
  cluster create (`depends_on` for ordering).
- **Egress lockdown** via Azure Firewall + UDR + FQDN tag.
- **Premium ACR** with **private endpoint** and `AcrPull` role assignment.
- **Bastion + jumpbox** as the operator entry point.
- **Module-free single-root** demo deliberately: every resource is in front of
  you so the wiring is obvious. In production, decompose into modules (see
  demo 04).

## Recommended next steps

- Add **Azure Policy add-on** and **Defender for Containers**.
- Replace the jumpbox with **AKS Run Command** (`az aks command invoke`) for
  even tighter perimeter — no jumpbox VM needed.
- Add **Application Gateway with Private IP** if you need ingress.
- Add a second spoke for data services (SQL MI, Cosmos) and peer it via the hub.

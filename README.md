# AKS Enterprise Landing Zone

A learning and demo resource for exploring **private AKS** deployment on Azure, using a **hub-and-spoke** network topology with full egress control, no public IPs on workloads or VMs, and Terraform modules — following production best practices throughout.

Use this repo to understand Terraform concepts, Azure networking patterns, and enterprise-grade AKS architecture.

## Architecture

```
                 ┌──────────────────────────────── Hub RG (rg-paks-<env>-hub) ───────────────────────────────────────────┐
                 │                                                                                                         │
                 │  ┌─────────────────────────────── Hub VNet (10.0.0.0/16) ──────────────────────────────────────────┐  │
                 │  │                                                                                                   │  │
   Operator ──▶  │  │ ┌──────────────────────┐    ┌──────────────────────┐    ┌──────────────────────┐                │  │
   (browser)     │  │ │ AzureBastionSubnet   │    │ AzureFirewallSubnet  │    │ snet-shared          │                │  │
                 │  │ │  Azure Bastion       │───▶│  Azure Firewall      │    │  Jumpbox (Linux or   │                │  │
                 │  │ └──────────────────────┘    └──────────┬───────────┘    │  Windows via os_type)│                │  │
                 │  │                                         │                └──────────┬───────────┘                │  │
                 │  └─────────────────────────────────────────┼────────────────────────── ┼ ──────────────────────────┘  │
                 │                                             │                           │                              │
                 │  ┌── Private DNS Zones (hub RG, linked to hub + spoke VNets) ────────────────────────────────────┐   │
                 │  │  • privatelink.<region>.azmk8s.io              → AKS private API endpoint                     │   │
                 │  │  • privatelink.azurecr.io                      → ACR private endpoint                         │   │
                 │  │  • privatelink.<region>.prometheus.monitor...  → Prometheus workspace                          │   │
                 │  │  • privatelink.grafana.azure.com               → Grafana endpoint                              │   │
                 │  └────────────────────────────────────────────────────────────────────────────────────────────────┘   │
                 │                                             │ forced egress (UDR)       │ kubectl /                    │
                 └─────────────────────────────────────────────┼────────────────────────── ┼ ───────────────────────────┘
                                                               │                           │ RDP via Bastion
                                                               ▼                           ▼
                 ┌────────────────────────── Spoke RG (rg-paks-<env>-spoke) ───────────────────────────────────────────┐
                 │                                                                                                       │
                 │  ┌─────────────────────────────── Spoke VNet (10.10.0.0/16) ──────────────────────────────────────┐ │
                 │  │                                                                                                  │ │
                 │  │ ┌──────────────────────┐    ┌──────────────────────┐                                           │ │
                 │  │ │ snet-aks             │    │ snet-pe              │                                           │ │
                 │  │ │   AKS nodes          │    │   PE for ACR         │                                           │ │
                 │  │ │   UDR → Firewall     │    │   PE for Grafana     │                                           │ │
                 │  │ └─────────┬────────────┘    │   PE for Prometheus  │                                           │ │
                 │  │           │ 0.0.0.0/0 → FW  └──────────────────────┘                                           │ │
                 │  └───────────┼──────────────────────────────────────────────────────────────────────────────────── ┘ │
                 │              │                                                                                        │
                 │  AKS cluster │  ACR · Azure Monitor Workspace · Grafana · Spoke Log Analytics                        │
                 └──────────────┼────────────────────────────────────────────────────────────────────────────────────── ┘
                                │ allowed FQDNs via Firewall
                                ▼ Internet / Azure services
```

**What the current Terraform implementation deploys:**

| Component | Notes |
|---|---|
| Hub VNet + 3 subnets | `AzureFirewallSubnet`, `AzureBastionSubnet`, `snet-shared` (jumpboxes) |
| Spoke VNet + 2 subnets | `snet-aks` (AKS nodes), `snet-pe` (private endpoints, network policies disabled) |
| Bidirectional VNet peerings | Hub ↔ spoke; forwarded traffic enabled both directions |
| **Azure Firewall (Standard)** + Firewall Policy | All cluster egress through one audited choke-point |
| AKS-required firewall rules | Minimal FQDN/port allow-list (network + application rule collections) |
| Route table on `snet-aks` | UDR: `0.0.0.0/0` → Firewall private IP (`userDefinedRouting`) |
| **Azure Bastion (Standard SKU)** | Browser-based SSH/RDP; tunneling + copy-paste enabled; no public VM IPs |
| **Jumpbox** in hub `snet-shared` | System-assigned MI + `AKS Cluster User Role`; configurable OS (`os_type = "linux"` or `"windows"`); one VM serves all spokes via VNet peering |
| 4 × Private DNS Zones | AKS API, ACR, Prometheus, Grafana — each linked to both hub + spoke VNets |
| **Private AKS cluster** | `private_cluster_enabled = true`, no public FQDN, BYO DNS zone, user-assigned identity |
| User-assigned MI for AKS | Pre-granted `Private DNS Zone Contributor` + `Network Contributor` before cluster creation |
| **Azure CNI Overlay + Cilium** | `network_plugin_mode = "overlay"`, `network_policy = "cilium"`, `network_data_plane = "cilium"` |
| AKS add-ons / features | OIDC issuer, Workload Identity, Azure Policy, Azure RBAC — all enabled |
| AKS operator access | `Azure Kubernetes Service RBAC Cluster Admin` granted to the operator identity |
| Auto-scaling user node pools | Defined in `node_pools` tfvars variable; managed by the `aks_node_pools` module |
| **Premium ACR** with private endpoint | `public_network_access_enabled = false` — all image pulls stay on-net |
| ACR role assignments | Kubelet → `AcrPull`; operator → `AcrPush`; jumpbox MI → `AcrPull` |
| **Azure Monitor Workspace** (Managed Prometheus) | Private endpoint (`prometheusMetrics`); no public access; DCR + DCR association to AKS |
| **Managed Grafana** (private) | Integrated with Monitor workspace; Grafana MI granted `Monitoring Data Reader` |
| Prometheus recording rules | Node (CPU, memory, disk, network) + container (CPU, memory, requests) rule groups |
| Prometheus alerting rules | 10 pre-built alerts: pod crash-looping, not-ready, node memory/disk/CPU pressure, HPA mismatch, PV filling up |
| **Diagnostic settings** (5 resources) | Firewall, AKS control-plane, ACR, Grafana, Monitor Workspace → Log Analytics |
| Hub Log Analytics workspace | `log-<name_suffix>-hub` in hub RG — receives Firewall diagnostic logs |
| Spoke Log Analytics workspace | `log-<name_suffix>-<uid>` in spoke RG — used by OMS agent + AKS/ACR/Grafana/Prometheus diagnostics |

## Module layout

```
.
├── main.tf            # Resource groups + 3-stage orchestration modules
├── variables.tf       # All input variables (with defaults)
├── outputs.tf         # Key resource IDs and connection info
├── providers.tf       # azurerm ~> 4.0, terraform >= 1.5.0
└── modules/
    ├── platform_stack/   # Stage 1: network, firewall, bastion, hub LAW, private DNS zones
    ├── core_stack/       # Stage 2: private AKS cluster + spoke Log Analytics workspace
    ├── addons_stack/     # Stage 3: ACR, Prometheus/Grafana, rule groups, jumpboxes, user node pools
    ├── hub_network/      # Building block modules used by platform_stack
    ├── firewall/
    ├── bastion/
    ├── spoke_network/
    ├── private_dns_zones/
    ├── private_aks/      # Building block module used by core_stack
    ├── private_acr/      # Building block modules used by addons_stack
    ├── managed_prometheus/
    ├── grafana/
    ├── recording_rules/
    ├── alerting_rules/
    ├── aks_node_pools/
    └── jumpbox/
```

Each module has `main.tf`, `variables.tf`, and `outputs.tf`.

### Dependency chain

Terraform uses staged orchestration plus module output references:

```
platform_stack  ──▶  core_stack   ──▶  addons_stack
```

Inside each stage, ordering is primarily output-driven (with targeted `depends_on` only where Azure ordering is strict).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- Azure CLI, authenticated:

  ```bash
  az login
  az account set --subscription "<your subscription id>"
  ```

## Environments

Three ready-to-use var files live under `envs/`. Each uses an isolated address
space so all three environments can exist in the same subscription simultaneously.

| File | Environment | Address spaces | AKS system pool | AKS user pool | Log retention |
|---|---|---|---|---|---|
| `envs/dev.tfvars` | `dev` | hub `10.0/16`, spoke `10.10/16` | D2s_v5 × 1–2 | D2s_v5 × 1–3 | 30 days |
| `envs/test.tfvars` | `test` | hub `10.1/16`, spoke `10.11/16` | D2s_v5 × 1–3 | D4s_v5 × 1–5 | 60 days |
| `envs/prod.tfvars` | `prod` | hub `10.2/16`, spoke `10.12/16` | D4s_v5 × 2–5 | D8s_v5 × 3–10 | 90 days |

Two variables are intentionally **not** in the var files because they are secret
or identity-specific:

| Variable | How to supply |
|---|---|
| `jumpbox_admin_password` | `export TF_VAR_jumpbox_admin_password='...'` |
| `operator_object_id` | Optional. Defaults to the currently authenticated principal (`az login` identity). Override with `export TF_VAR_operator_object_id=$(az ad signed-in-user show --query id -o tsv)` |

## Usage

### Deploy to a specific environment

```bash
terraform init

# Set secrets once as env vars (never in var files)
export TF_VAR_jumpbox_admin_password='<a-strong-password>'
# operator_object_id is optional — omit to default to the logged-in principal
# export TF_VAR_operator_object_id=$(az ad signed-in-user show --query id -o tsv)

# Deploy dev
terraform apply -var-file=envs/dev.tfvars

# Deploy test
terraform apply -var-file=envs/test.tfvars

# Deploy prod (consider a separate state backend per env — see docs/enterprise-concepts.md)
terraform apply -var-file=envs/prod.tfvars
```

### Destroy an environment

```bash
terraform destroy -var-file=envs/dev.tfvars
```

### Separate state per environment (recommended for prod)

Configure a remote backend in `providers.tf` with a different state key per
environment. A common pattern uses the environment name as part of the blob path:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-tfstate"
  storage_account_name = "sttfstate<org>"
  container_name       = "tfstate"
  key                  = "aks-landing-zone/<env>.tfstate"   # e.g. aks-landing-zone/prod.tfstate
}
```

Pass the key at init time: `terraform init -backend-config="key=aks-landing-zone/prod.tfstate"`

> ⚠️ **Cost warning.** This configuration provisions expensive Azure resources:
> Azure Firewall (~$900/mo), Bastion (~$140/mo), AKS control plane, Premium ACR, and public IPs.
> Always run `terraform destroy` when done experimenting.

## Connecting to the cluster

### Jumpbox (SSH or RDP via Bastion)

The jumpbox module deploys a single VM whose OS is controlled by the `os_type` variable (default: `"linux"`). Both flavours are reachable only via Azure Bastion — no public IP.

#### Linux (default)

1. In the Azure portal, open the jumpbox VM in **`rg-paks-<env>-hub`** → **Connect → Bastion**.
2. Log in with `jumpbox_admin_username` / `jumpbox_admin_password`.
3. On the jumpbox:

   ```bash
   az login
   az aks get-credentials -g rg-paks-<env>-spoke -n aks-paks-<env>
   kubelogin convert-kubeconfig -l azurecli
   kubectl get nodes
   k9s
   ```

   The `kubectl` call resolves the private API FQDN to a **private IP** via the
   Private DNS Zone linked to the hub VNet.

   ![k9s console](images/k9s-console.png)

#### Windows (opt-in)

Set `os_type = "windows"` in your `envs/*.tfvars` (or via `-var`) to deploy a Windows Server jumpbox instead. On first boot, a Custom Script Extension installs toolchain tools via Chocolatey.

1. In the Azure portal, open the jumpbox VM in **`rg-paks-<env>-hub`** → **Connect → Bastion (RDP)**.
2. Log in with `jumpbox_admin_username` / `jumpbox_admin_password`.
3. Once the bootstrap extension completes, open PowerShell and run:

   ```powershell
   az login
   az aks get-credentials -g rg-paks-<env>-spoke -n aks-paks-<env>
   kubelogin convert-kubeconfig -l azurecli
   kubectl get nodes
   helm version
   ```

### Jumpbox tooling installed by bootstrap

| `os_type` | Installed tools |
|---|---|
| `linux` | Azure CLI, kubectl, kubelogin, Helm, Docker Engine/CLI, k9s |
| `windows` | Azure CLI, kubectl, kubelogin, Helm, git, Docker CLI, Headlamp |

Supply a custom `custom_data` (Linux) or `bootstrap_script` (Windows) variable on the `jumpbox` module to override the default toolchain.

## Why this design?

- **Private cluster** removes the public API endpoint — required by PCI, HIPAA, and most internal banking / finance security baselines.
- **BYO Private DNS zone** lets multiple spokes resolve the API name and gives Terraform full lifecycle ownership of the zone (auditable, versioned, destroyable).
- **User-assigned MI for AKS** is mandatory with a BYO DNS zone — AKS needs `Private DNS Zone Contributor` on the zone *before* the cluster is created.
- **Azure Firewall + UDR** centralises all egress through a single auditable point. AKS has a published list of required FQDNs and ports; this repo encodes them in a Firewall Policy.
- **Private ACR** prevents image exfiltration and external pull-through. The kubelet authenticates via MSI — no registry secrets in the cluster.
- **Azure CNI Overlay + Cilium** gives each pod its own IP from a dedicated overlay CIDR (avoids subnet exhaustion), while Cilium provides eBPF-based network policy enforcement and dataplane acceleration.
- **OIDC issuer + Workload Identity** allows pods to exchange a Kubernetes service account token for an Azure AD token — no secrets mounted into pods.
- **Azure Policy add-on** enforces OPA-based governance on the cluster (admission webhook backed by Azure Policy).
- **Jumpboxes in hub `snet-shared`** means a single management VM reaches all spokes through VNet peering — consistent toolchain, no per-spoke VM duplication. The `os_type` variable switches between Linux and Windows without changing any other wiring.
- **Diagnostic settings on all major resources** (Firewall, AKS, ACR, Grafana, Prometheus) feed two Log Analytics workspaces: one for the hub/firewall, one for spoke/workload diagnostics.
- **Staged orchestration (`platform → core → addons`)** gives predictable rollout sequencing for enterprise environments while keeping module boundaries reusable.

## Azure CAF Alignment

This repo follows the [Azure Cloud Adoption Framework hub-spoke topology](https://learn.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke). The table below records the CAF audit findings and what changes if you scale to multiple spokes.

### Current placement — CAF verdict

| Resource | Current location | CAF verdict |
|---|---|---|
| Azure Firewall | Hub RG | ✅ Shared connectivity — hub |
| Azure Bastion | Hub RG | ✅ Shared management access — hub |
| **Jumpbox** (configurable OS) | Hub RG (`snet-shared`) | ✅ Shared ops tooling — hub |
| Private DNS Zones (all 4) | Hub RG, linked to hub + spoke VNets | ✅ Shared platform DNS — hub |
| Hub Log Analytics Workspace | Hub RG | ✅ Platform diagnostics — hub |
| VNet peerings | Hub RG (hub-side) | ✅ Connectivity layer — hub |
| AKS cluster | Spoke RG | ✅ Workload — spoke |
| Route table / UDR | Spoke RG | ✅ Workload networking — spoke |
| Private endpoints (ACR, Prometheus, Grafana) | Spoke RG (`snet-pe`) | ✅ Workload NICs — spoke |
| ACR | Spoke RG | ⚠️ Single workload → spoke OK; shared registry → hub/shared services |
| Azure Monitor Workspace (Prometheus) | Spoke RG | ⚠️ Per-team workload observability → spoke OK; platform-level metrics → add hub workspace |
| Grafana | Spoke RG | ⚠️ Per-team dashboards → spoke OK; cross-spoke unified view → add hub Grafana with multi-workspace integration |
| Spoke Log Analytics Workspace | Spoke RG | ⚠️ Single workload → spoke OK; centralised logging → hub |

### What changes when you scale to multiple spokes

The current design is correct for a single-spoke, single-AKS environment. When you add a second spoke (e.g. a data-services spoke or a second team's AKS cluster), three resources should move from the spoke to the hub or a dedicated **shared services** spoke:

#### 1 — ACR → hub / shared services

A container registry that serves multiple AKS clusters should not live inside one cluster's spoke. Centralise it:

- Create ACR in the hub RG (or a dedicated `rg-paks-shared` RG)
- Move `privatelink.azurecr.io` DNS zone link to all peered spokes
- Grant `AcrPull` to every spoke's kubelet MSI

#### 2 — Prometheus + Grafana: federated observability model

The right answer here is **use-case driven, not a binary hub-or-spoke choice**:

**Per-spoke Prometheus + Grafana (keep what this repo already deploys)**
- Each team/spoke owns its Azure Monitor Workspace and Grafana instance
- Independent alerting rules, dashboards, and RBAC — teams are autonomous
- Workload SLOs are defined and managed by the team that owns the workload
- This is the correct model when teams have different on-call rotations or SLAs

**Add a hub Grafana for platform-level resources**
- The platform/ops team needs visibility into resources that don't belong to any one spoke: Firewall, Bastion, hub Log Analytics, policy compliance
- Azure Managed Grafana supports multiple `azure_monitor_workspace_integrations` — one hub Grafana instance can query every spoke's Monitor Workspace simultaneously
- This gives the platform team a single pane of glass without taking ownership away from spoke teams

**The resulting federated topology:**
```
Hub Grafana (platform team — cross-spoke view)
  ├── data source: hub Log Analytics   (Firewall, Bastion diagnostics)
  ├── data source: spoke-A Monitor Workspace  (AKS cluster A metrics)
  └── data source: spoke-B Monitor Workspace  (AKS cluster B metrics)

Spoke-A Grafana (team A — workload view)
  └── data source: spoke-A Monitor Workspace

Spoke-B Grafana (team B — workload view)
  └── data source: spoke-B Monitor Workspace
```

Platform-level resources (Firewall logs, Bastion session counts, hub LAW diagnostics) should always feed into the hub Grafana — they have no natural spoke owner.

#### 3 — Consolidate Log Analytics Workspaces

Currently there are two workspaces: one hub workspace (Firewall diagnostics) and one spoke workspace (AKS + addon diagnostics). With multiple spokes, consider merging into a single hub workspace:

- Centralised query surface across all resources
- Simpler RBAC — platform team has one workspace to manage
- Reduces cost (no duplicate ingestion of common log types)

### What does **not** change regardless of scale

| Resource | Reason |
|---|---|
| Private DNS Zones stay in hub | Already correct — DNS is always a platform/connectivity concern in CAF |
| Jumpbox stays in hub `snet-shared` | One management VM reaches all spokes through VNet peering |
| Firewall + Bastion stay in hub | Hub is the single egress/ingress control point by design |
| Private endpoints stay in each spoke | The NIC must live in the spoke subnet so traffic stays local to that VNet |

## Egress rules

AKS [requires specific egress](https://learn.microsoft.com/azure/aks/limit-egress-traffic). This repo implements a minimal allow-list in the Firewall Policy:

**Network rules**
- TCP/9000 to `AzureCloud.<region>` (tunnel front-end)
- UDP/1194 to `AzureCloud.<region>` (legacy tunnel)
- UDP/123 to `*` (NTP)
- TCP/443 to `AzureCloud.<region>`, `AzureMonitor`, `MicrosoftContainerRegistry`

**Application rules (HTTPS)**
- `AzureKubernetesService` FQDN tag (single line, covers the full official list)
- `mcr.microsoft.com`, `*.data.mcr.microsoft.com`, `*.cdn.mscr.io`
- `management.azure.com`, `login.microsoftonline.com`
- `packages.microsoft.com`, `acs-mirror.azureedge.net`
- `*.ods.opinsights.azure.com`, `*.oms.opinsights.azure.com`, `*.monitoring.azure.com`

## Further reading

- [`docs/enterprise-concepts.md`](docs/enterprise-concepts.md) — state strategy, module tiers, environments, identity, policy-as-code, drift, naming/tagging.
- [`docs/ci-cd-pipeline.md`](docs/ci-cd-pipeline.md) — reference GitHub Actions pipeline using Azure OIDC with plan-as-PR-comment and gated production apply.

## Recommended next steps

- Add **Application Gateway (private IP)** or **NGINX Ingress Controller** for inbound traffic.
- Add a second spoke for data services (SQL Managed Instance, Cosmos DB) and peer it through the hub.
- Configure **Workload Identity** on your application pods — the OIDC issuer and WI webhook are already enabled. Create a federated credential and `ServiceAccount` per workload to access Key Vault without any secrets.
- Enable **Microsoft Defender for Containers** for runtime threat detection on AKS nodes and the container registry.
- Replace the jumpboxes with **AKS Run Command** (`az aks command invoke`) for an even tighter perimeter where no management VMs are needed.
- Add **Azure DDoS Network Protection** on the hub VNet for production workloads.
- Integrate **Azure Monitor Alerts** by populating `alert_action_group_ids` in your `envs/prod.tfvars` to route the pre-built Prometheus alert rules to email/PagerDuty/Teams.

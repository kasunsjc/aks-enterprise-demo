# Demo 04 — Reusable Modules + Hub-and-Spoke Network

A real enterprise rarely deploys a single VNet. The most common Azure landing
zone pattern is **hub-and-spoke**:

- A **hub** VNet hosts shared services (firewall, DNS, VPN/ExpressRoute, Bastion).
- **Spoke** VNets host workloads (apps, data, etc.) and **peer** to the hub.
- All egress to the internet and cross-spoke traffic flows through the hub.

This demo demonstrates:

- Writing **first-party modules** under `modules/` (network + spoke).
- Composing them in an environment-specific root under `envs/dev`.
- Using `for_each` to dynamically create N spokes from a map.
- Bidirectional VNet peering and address-space planning.
- Module input validation and structured outputs.

## Layout

```
demos/04-modules-hub-spoke/
├── modules/
│   ├── network/   # hub VNet, subnets, NSGs
│   └── spoke/     # spoke VNet, subnets, peering to hub
└── envs/
    └── dev/       # root module wiring everything together
```

## Concepts taught

| Concept                             | Where you can see it                                         |
| ----------------------------------- | ------------------------------------------------------------ |
| Module composition                  | `envs/dev/main.tf` calling `modules/network` and `modules/spoke` |
| `for_each` over a map of objects    | `envs/dev/main.tf` creating multiple spokes                  |
| Module input contracts + validation | `modules/*/variables.tf`                                     |
| Cross-module data sharing           | `module.hub.vnet_id` consumed by spokes                      |
| Output composition for callers      | `envs/dev/outputs.tf`                                        |

## Why not put everything in one file?

Real enterprises have:

- Many teams shipping changes in parallel; modules give clean ownership boundaries.
- Compliance/security baked into modules (NSG defaults, naming rules, tagging).
- Reuse across `dev`, `stage`, `prod`, and across product teams.

Modules turn Terraform into a **platform**, not just scripts.

## Usage

```bash
cd demos/04-modules-hub-spoke/envs/dev
terraform init
terraform plan
terraform apply
```

> Note: For brevity this demo doesn't deploy Azure Firewall, Bastion, or
> Private DNS Zones. Those are excellent next steps once you have the topology
> running.

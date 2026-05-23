# ---------------------------------------------------------------------------
# prod — production. High availability, larger VMs, longer log retention,
#        and multiple node pools for different workload tiers.
# ---------------------------------------------------------------------------

environment        = "prod"
unique_identifier  = "contso" # ≤6 chars; org/subscription identifier. Full ACR name: acrpaksprod<id>, LAW: log-paks-prod-<id>
location           = "eastus"
kubernetes_version = "1.30"

# Network — isolated address space for prod
hub_address_space   = ["10.2.0.0/16"]
spoke_address_space = ["10.12.0.0/16"]

hub_subnets = {
  firewall = "10.2.1.0/26"
  bastion  = "10.2.2.0/26"
  shared   = "10.2.3.0/24"
}

spoke_subnets = {
  aks = "10.12.1.0/24"
  pe  = "10.12.2.0/24"
}

# AKS — system pool (HA: min 2 for zone redundancy)
system_node_vm_size   = "Standard_D4s_v5"
system_node_min_count = 2
system_node_max_count = 5

# AKS — additional user pools
# "user"    — general workloads
# "compute" — CPU-intensive batch / ML inference workloads
node_pools = {
  user = {
    vm_size   = "Standard_D8s_v5"
    min_count = 3
    max_count = 10
  }
  compute = {
    vm_size     = "Standard_F8s_v2"
    min_count   = 0
    max_count   = 20
    node_labels = { "workload-type" = "compute" }
    node_taints = ["workload-type=compute:NoSchedule"]
  }
}

# Observability — 90-day retention satisfies most audit requirements
log_retention_days     = 90
grafana_major_version  = 10
alert_action_group_ids = []
# Populate alert_action_group_ids with Action Group resource IDs to receive alerts:
# alert_action_group_ids = ["/subscriptions/.../resourceGroups/.../providers/microsoft.insights/actionGroups/..."]

# Jumpbox — slightly larger for running build / debugging tools
jumpbox_vm_size        = "Standard_D2s_v5"
jumpbox_admin_username = "azureadmin"
# jumpbox_admin_password — set via TF_VAR_jumpbox_admin_password or -var flag
# operator_object_id     — set via TF_VAR_operator_object_id or -var flag

tags = {
  workload    = "private-aks-landing-zone"
  environment = "prod"
  managed_by  = "terraform"
  cost_center = "platform"
  owner       = "platform-team"
}

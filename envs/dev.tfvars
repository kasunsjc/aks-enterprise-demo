# ---------------------------------------------------------------------------
# dev — lightweight, cost-optimised. Used for active development and
#       feature-branch testing. No HA requirements.
# ---------------------------------------------------------------------------

environment        = "dev"
unique_identifier  = "contso" # ≤6 chars; org/subscription identifier. Full ACR name: acrpaksdev<id>, LAW: log-paks-dev-<id>
location           = "northeurope"
kubernetes_version = "1.34"

# Network — isolated address space for dev
hub_address_space   = ["10.0.0.0/16"]
spoke_address_space = ["10.10.0.0/16"]

hub_subnets = {
  firewall = "10.0.1.0/26"
  bastion  = "10.0.2.0/26"
  shared   = "10.0.3.0/24"
}

spoke_subnets = {
  aks = "10.10.1.0/24"
  pe  = "10.10.2.0/24"
}

# AKS — system pool (stays in cluster resource)
system_node_vm_size   = "Standard_D2s_v3"
system_node_min_count = 1
system_node_max_count = 2

# AKS — additional user pools (managed by aks_node_pools module)
node_pools = {
  user = {
    vm_size   = "Standard_D2s_v3"
    min_count = 1
    max_count = 3
  }
}

# Observability
log_retention_days     = 30
grafana_major_version  = 12
alert_action_group_ids = []

# Jumpbox
jumpbox_vm_size        = "Standard_B2s"
jumpbox_admin_username = "azureadmin"
# jumpbox_admin_password — set via TF_VAR_jumpbox_admin_password or -var flag
# operator_object_id     — set via TF_VAR_operator_object_id or -var flag

# Windows Jumpbox
windows_jumpbox_vm_size        = "Standard_D2s_v3"
windows_jumpbox_admin_username = "azureadmin"
# windows_jumpbox_admin_password — set via TF_VAR_windows_jumpbox_admin_password or -var flag

tags = {
  workload    = "private-aks-landing-zone"
  environment = "dev"
  managed_by  = "terraform"
  cost_center = "engineering"
}

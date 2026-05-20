# ---------------------------------------------------------------------------
# test — integration / QA environment. Mirrors prod topology at reduced scale.
#        Separate address space to allow future hub peering alongside prod.
# ---------------------------------------------------------------------------

environment        = "test"
unique_identifier  = "contoso" # ≤6 chars; appended to ACR and Log Analytics names
location           = "eastus"
kubernetes_version = "1.30"

# Network — isolated address space for test
hub_address_space   = ["10.1.0.0/16"]
spoke_address_space = ["10.11.0.0/16"]

hub_subnets = {
  firewall = "10.1.1.0/26"
  bastion  = "10.1.2.0/26"
  shared   = "10.1.3.0/24"
}

spoke_subnets = {
  aks     = "10.11.1.0/24"
  pe      = "10.11.2.0/24"
  jumpbox = "10.11.3.0/27"
}

# AKS — system pool
system_node_vm_size   = "Standard_D2s_v5"
system_node_min_count = 1
system_node_max_count = 3

# AKS — additional user pools
node_pools = {
  user = {
    vm_size   = "Standard_D4s_v5"
    min_count = 1
    max_count = 5
  }
}

# Observability
log_retention_days     = 60
grafana_major_version  = 10
alert_action_group_ids = []

# Jumpbox
jumpbox_vm_size        = "Standard_B2s"
jumpbox_admin_username = "azureadmin"
# jumpbox_admin_password — set via TF_VAR_jumpbox_admin_password or -var flag
# operator_object_id     — set via TF_VAR_operator_object_id or -var flag

tags = {
  workload    = "private-aks-landing-zone"
  environment = "test"
  managed_by  = "terraform"
  cost_center = "engineering"
}

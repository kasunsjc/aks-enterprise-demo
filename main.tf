locals {
  name_suffix = "paks-${var.environment}"
  tags = merge(var.tags, {
    environment = var.environment
  })
}

# ---------------------------------------------------------------------------
# Resource groups — one for shared hub resources, one for spoke workloads.
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "hub" {
  name     = "rg-${local.name_suffix}-hub"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "rg-${local.name_suffix}-spoke"
  location = var.location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# Module: hub_network
# Hub VNet + AzureFirewallSubnet / AzureBastionSubnet / snet-shared.
# ---------------------------------------------------------------------------
module "hub_network" {
  source = "./modules/hub_network"

  name_suffix          = local.name_suffix
  resource_group_name  = azurerm_resource_group.hub.name
  location             = azurerm_resource_group.hub.location
  address_space        = var.hub_address_space
  subnet_cidr_firewall = var.hub_subnets.firewall
  subnet_cidr_bastion  = var.hub_subnets.bastion
  subnet_cidr_shared   = var.hub_subnets.shared
  tags                 = local.tags
}

# ---------------------------------------------------------------------------
# Module: hub_security
# Azure Firewall (with AKS egress rules) + Azure Bastion.
# Depends on hub_network implicitly through subnet ID references.
# ---------------------------------------------------------------------------
module "hub_security" {
  source = "./modules/hub_security"

  name_suffix         = local.name_suffix
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  firewall_subnet_id  = module.hub_network.firewall_subnet_id
  bastion_subnet_id   = module.hub_network.bastion_subnet_id
  aks_node_cidr       = var.spoke_subnets.aks
  location_shortcode  = var.location
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Module: spoke_network
# Spoke VNet + subnets + bidirectional VNet peerings + UDR (egress → FW).
# firewall_private_ip comes from hub_security, creating an implicit dependency.
# ---------------------------------------------------------------------------
module "spoke_network" {
  source = "./modules/spoke_network"

  name_suffix             = local.name_suffix
  resource_group_name     = azurerm_resource_group.spoke.name
  location                = azurerm_resource_group.spoke.location
  address_space           = var.spoke_address_space
  subnet_cidr_aks         = var.spoke_subnets.aks
  subnet_cidr_pe          = var.spoke_subnets.pe
  subnet_cidr_jumpbox     = var.spoke_subnets.jumpbox
  hub_vnet_id             = module.hub_network.vnet_id
  hub_vnet_name           = module.hub_network.vnet_name
  hub_resource_group_name = azurerm_resource_group.hub.name
  firewall_private_ip     = module.hub_security.firewall_private_ip
  tags                    = local.tags
}

# ---------------------------------------------------------------------------
# Module: jumpbox
# Linux VM (no public IP) with cloud-init. Create BEFORE private_acr so that
# the jumpbox MSI object ID is available for the AcrPull assignment in ACR.
# The jumpbox AcrPull role assignment is managed by the private_acr module.
# ---------------------------------------------------------------------------
module "jumpbox" {
  source = "./modules/jumpbox"

  name_suffix         = local.name_suffix
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  jumpbox_subnet_id   = module.spoke_network.jumpbox_subnet_id
  vm_size             = var.jumpbox_vm_size
  admin_username      = var.jumpbox_admin_username
  admin_password      = var.jumpbox_admin_password

  # AKS role assignment (Cluster User) is managed inside the jumpbox module.
  # The AcrPull role assignment for the jumpbox MSI is managed by private_acr.
  aks_cluster_id = module.private_aks.cluster_id
  tags           = local.tags
}

# ---------------------------------------------------------------------------
# Module: windows_jumpbox
# Windows Server VM (no public IP) with Custom Script Extension that installs
# Azure CLI, kubectl, Helm, and git via Chocolatey. Reachable via Bastion RDP.
# Create BEFORE private_acr so the Windows jumpbox MSI is available for AcrPull.
# ---------------------------------------------------------------------------
module "windows_jumpbox" {
  source = "./modules/windows_jumpbox"

  name_suffix         = local.name_suffix
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  jumpbox_subnet_id   = module.spoke_network.jumpbox_subnet_id
  vm_size             = var.windows_jumpbox_vm_size
  admin_username      = var.windows_jumpbox_admin_username
  admin_password      = var.windows_jumpbox_admin_password
  aks_cluster_id      = module.private_aks.cluster_id
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Module: private_aks
# BYO Private DNS zone, UAMI, Log Analytics, private AKS cluster + node pools.
# Depends on spoke_network (subnet ID) and jumpbox not needed here.
# ---------------------------------------------------------------------------
module "private_aks" {
  source = "./modules/private_aks"

  name_suffix             = local.name_suffix
  unique_identifier       = var.unique_identifier
  resource_group_name     = azurerm_resource_group.spoke.name
  location                = azurerm_resource_group.spoke.location
  kubernetes_version      = var.kubernetes_version
  aks_subnet_id           = module.spoke_network.aks_subnet_id
  spoke_vnet_id           = module.spoke_network.vnet_id
  hub_vnet_id             = module.hub_network.vnet_id
  hub_resource_group_name = azurerm_resource_group.hub.name
  tenant_id               = data.azurerm_client_config.current.tenant_id
  operator_object_id      = var.operator_object_id
  system_node_vm_size     = var.system_node_vm_size
  system_node_min_count   = var.system_node_min_count
  system_node_max_count   = var.system_node_max_count
  log_retention_days      = var.log_retention_days
  tags                    = local.tags
}

# ---------------------------------------------------------------------------
# Module: aks_node_pools
# Additional user node pools — managed independently of the cluster resource.
# Add, remove, or resize pools without touching the private_aks module.
# ---------------------------------------------------------------------------
module "aks_node_pools" {
  source = "./modules/aks_node_pools"

  kubernetes_cluster_id = module.private_aks.cluster_id
  aks_subnet_id         = module.spoke_network.aks_subnet_id
  node_pools            = var.node_pools
  tags                  = local.tags
}

# ---------------------------------------------------------------------------
# Module: private_acr
# Premium ACR, private endpoint + DNS zone, role assignments.
# Needs the AKS kubelet identity (from private_aks) and jumpbox MSI (jumpbox).
# ---------------------------------------------------------------------------
module "private_acr" {
  source = "./modules/private_acr"

  name_suffix                        = local.name_suffix
  unique_identifier                  = var.unique_identifier
  resource_group_name                = azurerm_resource_group.spoke.name
  location                           = azurerm_resource_group.spoke.location
  pe_subnet_id                       = module.spoke_network.pe_subnet_id
  spoke_vnet_id                      = module.spoke_network.vnet_id
  hub_vnet_id                        = module.hub_network.vnet_id
  hub_resource_group_name            = azurerm_resource_group.hub.name
  aks_kubelet_object_id              = module.private_aks.kubelet_identity_object_id
  operator_object_id                 = var.operator_object_id
  jumpbox_identity_object_id         = module.jumpbox.identity_object_id
  windows_jumpbox_identity_object_id = module.windows_jumpbox.identity_object_id
  tags                               = local.tags
}

# ---------------------------------------------------------------------------
# Module: monitoring
# Azure Monitor workspace (Managed Prometheus) + Managed Grafana.
# Both services use private endpoints. Recording and alerting rules are in
# separate submodules for independent lifecycle management.
# ---------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  name_suffix             = local.name_suffix
  resource_group_name     = azurerm_resource_group.spoke.name
  location                = azurerm_resource_group.spoke.location
  aks_cluster_id          = module.private_aks.cluster_id
  pe_subnet_id            = module.spoke_network.pe_subnet_id
  spoke_vnet_id           = module.spoke_network.vnet_id
  hub_vnet_id             = module.hub_network.vnet_id
  hub_resource_group_name = azurerm_resource_group.hub.name
  action_group_ids        = var.alert_action_group_ids
  grafana_major_version   = var.grafana_major_version
  tags                    = local.tags
}

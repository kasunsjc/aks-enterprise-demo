locals {
  name_suffix = "paks-${var.environment}"
  tags = merge(var.tags, {
    environment = var.environment
  })
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
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

  # These IDs are used for role assignments on the AKS cluster and ACR.
  # They are not yet created, so we pass placeholder-free references that
  # Terraform will resolve after the cluster/ACR modules run.
  # Role assignments are inside the jumpbox module itself, so Terraform
  # correctly chains creation order.
  aks_cluster_id = module.private_aks.cluster_id
  acr_id         = module.private_acr.acr_id
  tags           = local.tags
}

# ---------------------------------------------------------------------------
# Module: private_aks
# BYO Private DNS zone, UAMI, Log Analytics, private AKS cluster + node pools.
# Depends on spoke_network (subnet ID) and jumpbox not needed here.
# ---------------------------------------------------------------------------
module "private_aks" {
  source = "./modules/private_aks"

  name_suffix             = local.name_suffix
  random_suffix           = random_string.suffix.result
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
  user_node_vm_size       = var.user_node_vm_size
  user_node_min_count     = var.user_node_min_count
  user_node_max_count     = var.user_node_max_count
  log_retention_days      = var.log_retention_days
  tags                    = local.tags
}

# ---------------------------------------------------------------------------
# Module: private_acr
# Premium ACR, private endpoint + DNS zone, role assignments.
# Needs the AKS kubelet identity (from private_aks) and jumpbox MSI (jumpbox).
# ---------------------------------------------------------------------------
module "private_acr" {
  source = "./modules/private_acr"

  name_suffix                = local.name_suffix
  random_suffix              = random_string.suffix.result
  resource_group_name        = azurerm_resource_group.spoke.name
  location                   = azurerm_resource_group.spoke.location
  pe_subnet_id               = module.spoke_network.pe_subnet_id
  spoke_vnet_id              = module.spoke_network.vnet_id
  hub_vnet_id                = module.hub_network.vnet_id
  hub_resource_group_name    = azurerm_resource_group.hub.name
  aks_kubelet_object_id      = module.private_aks.kubelet_identity_object_id
  operator_object_id         = var.operator_object_id
  jumpbox_identity_object_id = module.jumpbox.identity_object_id
  tags                       = local.tags
}

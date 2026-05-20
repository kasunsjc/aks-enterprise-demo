# ============================================================================
# Hub VNet + subnets
# ============================================================================
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${local.name_suffix}-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = var.hub_address_space
  tags                = local.tags
}

resource "azurerm_subnet" "hub_firewall" {
  # MUST be exactly "AzureFirewallSubnet"
  name                 = local.firewall_subnet_name
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnets.firewall]
}

resource "azurerm_subnet" "hub_bastion" {
  # MUST be exactly "AzureBastionSubnet"
  name                 = local.bastion_subnet_name
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnets.bastion]
}

resource "azurerm_subnet" "hub_shared" {
  name                 = "snet-shared"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnets.shared]
}

# ============================================================================
# Spoke VNet + subnets
# ============================================================================
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${local.name_suffix}-spoke"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  address_space       = var.spoke_address_space
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.spoke_subnets.aks]
}

resource "azurerm_subnet" "pe" {
  name                              = "snet-pe"
  resource_group_name               = azurerm_resource_group.spoke.name
  virtual_network_name              = azurerm_virtual_network.spoke.name
  address_prefixes                  = [var.spoke_subnets.pe]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "jumpbox" {
  name                 = "snet-jumpbox"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.spoke_subnets.jumpbox]
}

# ============================================================================
# VNet peering (bidirectional)
# ============================================================================
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "hub-to-spoke"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "spoke-to-hub"
  resource_group_name          = azurerm_resource_group.spoke.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# ============================================================================
# Route table — force AKS egress through the Azure Firewall
# ============================================================================
resource "azurerm_route_table" "aks_egress" {
  name                = "rt-${local.name_suffix}-aks-egress"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = local.tags
}

resource "azurerm_route" "aks_default" {
  name                   = "default-to-firewall"
  resource_group_name    = azurerm_resource_group.spoke.name
  route_table_name       = azurerm_route_table.aks_egress.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.aks_egress.id

  # Without this, AKS create may race with route propagation.
  depends_on = [
    azurerm_firewall.hub,
    azurerm_firewall_policy_rule_collection_group.aks,
  ]
}

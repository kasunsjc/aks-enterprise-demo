locals {
  tags = {
    environment = var.environment
    managed_by  = "terraform"
    workload    = "platform-networking"
  }
}

resource "azurerm_resource_group" "hub" {
  name     = "rg-network-hub-${var.environment}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "spokes" {
  for_each = var.spokes

  name     = "rg-network-${each.key}-${var.environment}"
  location = var.location
  tags     = local.tags
}

module "hub" {
  source = "../../modules/network"

  name                = "vnet-hub-${var.environment}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  address_space       = var.hub_address_space
  subnets             = var.hub_subnets
  tags                = local.tags
}

module "spoke" {
  source = "../../modules/spoke"

  for_each = var.spokes

  name                    = "vnet-${each.key}-${var.environment}"
  resource_group_name     = azurerm_resource_group.spokes[each.key].name
  location                = var.location
  address_space           = each.value.address_space
  subnets                 = each.value.subnets
  hub_vnet_id             = module.hub.vnet_id
  hub_vnet_name           = module.hub.vnet_name
  hub_resource_group_name = azurerm_resource_group.hub.name
  tags                    = local.tags
}

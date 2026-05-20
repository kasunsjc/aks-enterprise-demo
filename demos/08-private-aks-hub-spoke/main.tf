locals {
  name_suffix = "paks-${var.environment}"
  tags = merge(var.tags, {
    environment = var.environment
  })

  # Azure-required exact subnet names.
  bastion_subnet_name  = "AzureBastionSubnet"
  firewall_subnet_name = "AzureFirewallSubnet"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

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

locals {
  name_suffix = "platform-${var.environment}"
  tags = merge(var.tags, {
    environment = var.environment
  })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

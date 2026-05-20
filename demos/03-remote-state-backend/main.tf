locals {
  name_prefix = "tfstate-${var.environment}"
  tags = merge(var.tags, {
    environment = var.environment
  })
}

resource "azurerm_resource_group" "state" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

resource "random_string" "sa_suffix" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_storage_account" "state" {
  name                              = lower(substr("st${replace(local.name_prefix, "-", "")}${random_string.sa_suffix.result}", 0, 24))
  resource_group_name               = azurerm_resource_group.state.name
  location                          = azurerm_resource_group.state.location
  account_tier                      = "Standard"
  account_replication_type          = "GRS"
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = true
  public_network_access_enabled     = true
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.tags
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

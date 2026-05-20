locals {
  name_suffix = "${var.app_name}-${var.environment}"
  tags = merge(var.tags, {
    environment = var.environment
    workload    = var.app_name
    managed_by  = "terraform"
  })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_service_plan" "this" {
  name                = "plan-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = var.service_plan_sku
  worker_count        = var.worker_count
  tags                = local.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = "app-${local.name_suffix}-${substr(md5(azurerm_resource_group.this.id), 0, 6)}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = var.https_only
  tags                = local.tags

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
    http2_enabled       = true

    application_stack {
      node_version = "20-lts"
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

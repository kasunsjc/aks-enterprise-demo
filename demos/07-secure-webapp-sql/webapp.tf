resource "azurerm_service_plan" "this" {
  name                = "plan-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "P1v3"
  tags                = local.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = "app-${local.name_suffix}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true
  tags                = local.tags

  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "Disabled"
    http2_enabled       = true

    application_stack {
      node_version = "20-lts"
    }

    vnet_route_all_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  # The web app gets the SQL connection string at runtime by *reference*,
  # never by value. This way the secret never enters app settings, logs,
  # or Terraform output in clear text.
  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE         = "1"
    SQL_CONNECTION_STRING            = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_connection_string.versionless_id})"
    KEY_VAULT_URI                    = azurerm_key_vault.this.vault_uri
    APPLICATIONINSIGHTS_ENABLE_AGENT = "true"
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  app_service_id = azurerm_linux_web_app.this.id
  subnet_id      = azurerm_subnet.app.id
}

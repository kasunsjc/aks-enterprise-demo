resource "azurerm_key_vault" "this" {
  name                          = "kv${replace(local.name_suffix, "-", "")}${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true # Renamed to rbac_authorization_enabled in azurerm v5
  purge_protection_enabled      = true
  soft_delete_retention_days    = 30
  public_network_access_enabled = true
  tags                          = local.tags
}

# Admin (you) can manage secrets.
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_id
}

# Web App identity can read secrets at runtime.
resource "azurerm_role_assignment" "kv_app_reader" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.this.identity[0].principal_id
}

# Wait for the admin role to propagate before writing secrets (Terraform
# would otherwise try to write a secret without permission).
resource "time_sleep" "wait_rbac" {
  depends_on      = [azurerm_role_assignment.kv_admin]
  create_duration = "30s"
}

resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  key_vault_id = azurerm_key_vault.this.id
  value = format(
    "Server=tcp:%s,1433;Database=%s;User ID=%s;Password=%s;Encrypt=true;Connection Timeout=30;",
    azurerm_mssql_server.this.fully_qualified_domain_name,
    azurerm_mssql_database.this.name,
    azurerm_mssql_server.this.administrator_login,
    random_password.sql_admin.result,
  )
  content_type = "text/plain"

  depends_on = [time_sleep.wait_rbac]
}

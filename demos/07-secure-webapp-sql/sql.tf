resource "random_password" "sql_admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_mssql_server" "this" {
  name                          = "sql-${local.name_suffix}-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  version                       = "12.0"
  administrator_login           = "sqladminuser"
  administrator_login_password  = random_password.sql_admin.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  tags                          = local.tags
}

resource "azurerm_mssql_database" "this" {
  name        = "appdb"
  server_id   = azurerm_mssql_server.this.id
  sku_name    = "S0"
  max_size_gb = 5
  tags        = local.tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-sql-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  subnet_id           = azurerm_subnet.pe.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-sql"
    private_connection_resource_id = azurerm_mssql_server.this.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

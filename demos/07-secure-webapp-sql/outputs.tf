output "web_app_url" {
  value = "https://${azurerm_linux_web_app.this.default_hostname}"
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "private_endpoint_id" {
  value = azurerm_private_endpoint.sql.id
}

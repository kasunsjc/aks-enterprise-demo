output "acr_id" {
  description = "Resource ID of the ACR."
  value       = azurerm_container_registry.this.id
}

output "acr_name" {
  description = "Name of the ACR (used for `az acr login`)."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Login server FQDN of the ACR."
  value       = azurerm_container_registry.this.login_server
}

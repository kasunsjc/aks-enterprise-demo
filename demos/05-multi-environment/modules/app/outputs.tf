output "resource_group_name" {
  value       = azurerm_resource_group.this.name
  description = "Resource group name."
}

output "web_app_name" {
  value       = azurerm_linux_web_app.this.name
  description = "Linux web app name."
}

output "web_app_default_hostname" {
  value       = azurerm_linux_web_app.this.default_hostname
  description = "Default URL hostname for the web app."
}

output "web_app_principal_id" {
  value       = azurerm_linux_web_app.this.identity[0].principal_id
  description = "System-assigned managed identity principal ID."
}

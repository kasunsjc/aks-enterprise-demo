output "resource_group_id" {
  description = "Resource Group ID."
  value       = azurerm_resource_group.this.id
}

output "resource_group_name" {
  description = "Resource Group name."
  value       = azurerm_resource_group.this.name
}

output "resource_group_name" {
  description = "Resource Group name."
  value       = azurerm_resource_group.this.name
}

output "storage_account_name" {
  description = "Storage account name."
  value       = azurerm_storage_account.this.name
}

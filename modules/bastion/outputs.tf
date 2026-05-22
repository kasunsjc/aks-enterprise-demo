output "bastion_name" {
  description = "Name of the Azure Bastion host."
  value       = azurerm_bastion_host.this.name
}

output "bastion_id" {
  description = "Resource ID of the Azure Bastion host."
  value       = azurerm_bastion_host.this.id
}

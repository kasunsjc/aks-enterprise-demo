output "vnet_id" {
  description = "Spoke VNet resource ID."
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Spoke VNet name."
  value       = azurerm_virtual_network.spoke.name
}

output "subnet_ids" {
  description = "Map of subnet name => ID."
  value       = { for k, s in azurerm_subnet.spoke : k => s.id }
}

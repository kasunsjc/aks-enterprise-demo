output "vnet_id" {
  description = "Resource ID of the hub VNet."
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "Hub VNet name."
  value       = azurerm_virtual_network.hub.name
}

output "subnet_ids" {
  description = "Map of subnet name => ID."
  value       = { for k, s in azurerm_subnet.hub : k => s.id }
}

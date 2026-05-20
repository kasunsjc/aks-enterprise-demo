output "vnet_id" {
  description = "Resource ID of the spoke VNet."
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Name of the spoke VNet."
  value       = azurerm_virtual_network.spoke.name
}

output "aks_subnet_id" {
  description = "Resource ID of the AKS node subnet."
  value       = azurerm_subnet.aks.id
}

output "pe_subnet_id" {
  description = "Resource ID of the private-endpoint subnet."
  value       = azurerm_subnet.pe.id
}

output "jumpbox_subnet_id" {
  description = "Resource ID of the jumpbox subnet."
  value       = azurerm_subnet.jumpbox.id
}

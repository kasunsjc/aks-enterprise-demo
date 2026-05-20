output "vnet_id" {
  description = "Resource ID of the hub VNet."
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "Name of the hub VNet."
  value       = azurerm_virtual_network.hub.name
}

output "firewall_subnet_id" {
  description = "Resource ID of AzureFirewallSubnet."
  value       = azurerm_subnet.firewall.id
}

output "bastion_subnet_id" {
  description = "Resource ID of AzureBastionSubnet."
  value       = azurerm_subnet.bastion.id
}

output "shared_subnet_id" {
  description = "Resource ID of snet-shared."
  value       = azurerm_subnet.shared.id
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall. Used as UDR next-hop."
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_id" {
  description = "Resource ID of the Azure Firewall."
  value       = azurerm_firewall.hub.id
}

output "firewall_policy_rule_collection_group_id" {
  description = "Resource ID of the AKS rule collection group (useful as a depends_on target)."
  value       = azurerm_firewall_policy_rule_collection_group.aks.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion host."
  value       = azurerm_bastion_host.hub.name
}

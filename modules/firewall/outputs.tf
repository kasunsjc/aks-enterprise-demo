output "firewall_id" {
  description = "Resource ID of the Azure Firewall."
  value       = azurerm_firewall.this.id
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall. Used as UDR next-hop."
  value       = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_policy_id" {
  description = "Resource ID of the Firewall Policy."
  value       = azurerm_firewall_policy.this.id
}

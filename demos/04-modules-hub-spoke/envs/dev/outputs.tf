output "hub_vnet_id" {
  description = "Hub VNet ID."
  value       = module.hub.vnet_id
}

output "spoke_vnet_ids" {
  description = "Map of spoke name => VNet ID."
  value       = { for k, m in module.spoke : k => m.vnet_id }
}

output "spoke_subnet_ids" {
  description = "Nested map of spoke => subnet name => subnet ID."
  value       = { for k, m in module.spoke : k => m.subnet_ids }
}

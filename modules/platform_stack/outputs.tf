output "hub_vnet_id" {
  value = module.hub_network.vnet_id
}

output "spoke_vnet_id" {
  value = module.spoke_network.vnet_id
}

output "aks_subnet_id" {
  value = module.spoke_network.aks_subnet_id
}

output "pe_subnet_id" {
  value = module.spoke_network.pe_subnet_id
}

output "jumpbox_subnet_id" {
  description = "Resource ID of the hub shared subnet where jumpboxes are deployed."
  value       = module.hub_network.shared_subnet_id
}

output "aks_dns_zone_id" {
  value = module.private_dns_zones.aks_dns_zone_id
}

output "acr_dns_zone_id" {
  value = module.private_dns_zones.acr_dns_zone_id
}

output "prometheus_dns_zone_id" {
  value = module.private_dns_zones.prometheus_dns_zone_id
}

output "grafana_dns_zone_id" {
  value = module.private_dns_zones.grafana_dns_zone_id
}

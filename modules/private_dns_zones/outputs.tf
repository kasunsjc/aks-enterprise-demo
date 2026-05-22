output "aks_dns_zone_id" {
  description = "AKS API server private DNS zone ID."
  value       = try(azurerm_private_dns_zone.aks[0].id, null)
}

output "aks_dns_zone_name" {
  description = "AKS API server private DNS zone name."
  value       = try(azurerm_private_dns_zone.aks[0].name, null)
}

output "prometheus_dns_zone_id" {
  description = "Prometheus private DNS zone ID."
  value       = try(azurerm_private_dns_zone.prometheus[0].id, null)
}

output "grafana_dns_zone_id" {
  description = "Grafana private DNS zone ID."
  value       = try(azurerm_private_dns_zone.grafana[0].id, null)
}

output "acr_dns_zone_id" {
  description = "Container Registry private DNS zone ID."
  value       = try(azurerm_private_dns_zone.acr[0].id, null)
}

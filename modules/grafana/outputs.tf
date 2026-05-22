output "grafana_endpoint" {
  description = "Azure Managed Grafana endpoint (accessible via private endpoint)."
  value       = azurerm_dashboard_grafana.this.endpoint
}

output "grafana_id" {
  description = "Resource ID of Grafana instance."
  value       = azurerm_dashboard_grafana.this.id
}

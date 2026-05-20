output "monitor_workspace_id" {
  description = "Resource ID of the Azure Monitor workspace (Managed Prometheus backend)."
  value       = azurerm_monitor_workspace.this.id
}

output "grafana_id" {
  description = "Resource ID of the Azure Managed Grafana instance."
  value       = azurerm_dashboard_grafana.this.id
}

output "grafana_endpoint" {
  description = "Endpoint URL of the Azure Managed Grafana instance (accessible via private endpoint)."
  value       = azurerm_dashboard_grafana.this.endpoint
}

output "grafana_identity_principal_id" {
  description = "Object ID of the Grafana system-assigned managed identity."
  value       = azurerm_dashboard_grafana.this.identity[0].principal_id
}

output "prometheus_dcr_id" {
  description = "Resource ID of the Prometheus Data Collection Rule."
  value       = azurerm_monitor_data_collection_rule.prometheus.id
}

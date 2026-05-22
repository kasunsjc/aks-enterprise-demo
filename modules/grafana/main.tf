# ============================================================================
# Azure Managed Grafana
# ============================================================================
resource "azurerm_dashboard_grafana" "this" {
  name                          = "grafana-${var.name_suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  grafana_major_version         = var.grafana_major_version
  public_network_access_enabled = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = var.monitor_workspace_id
  }
}

# Grafana needs Monitoring Data Reader on the Monitor workspace
resource "azurerm_role_assignment" "grafana_monitor_reader" {
  scope                = var.monitor_workspace_id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
}

# Private endpoint
resource "azurerm_private_endpoint" "grafana" {
  name                = "pe-${var.name_suffix}-grafana"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name_suffix}-grafana"
    private_connection_resource_id = azurerm_dashboard_grafana.this.id
    subresource_names              = ["grafana"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "grafana-dns-zone-group"
    private_dns_zone_ids = [var.grafana_dns_zone_id]
  }
}

# ============================================================================
# Diagnostic settings — ship Grafana logs + metrics to Log Analytics.
# ============================================================================
resource "azurerm_monitor_diagnostic_setting" "grafana" {
  name                       = "diag-${var.name_suffix}-grafana"
  target_resource_id         = azurerm_dashboard_grafana.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "GrafanaLogs" }

  enabled_metric { category = "AllMetrics" }
}

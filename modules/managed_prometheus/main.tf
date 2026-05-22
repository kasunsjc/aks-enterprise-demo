# ============================================================================
# Azure Monitor Workspace — Managed Prometheus backend.
# ============================================================================
resource "azurerm_monitor_workspace" "this" {
  name                          = "amw-${var.name_suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  public_network_access_enabled = false
  tags                          = var.tags
}

# Private endpoint
resource "azurerm_private_endpoint" "monitor_workspace" {
  name                = "pe-${var.name_suffix}-prometheus"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name_suffix}-prometheus"
    private_connection_resource_id = azurerm_monitor_workspace.this.id
    subresource_names              = ["prometheusMetrics"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "prometheus-dns-zone-group"
    private_dns_zone_ids = [var.prometheus_dns_zone_id]
  }
}

# Data Collection Rule
resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                = "dcr-${var.name_suffix}-prometheus"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  description         = "Collects Prometheus metrics from AKS."

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.this.id
      name               = "MonitoringAccount"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount"]
  }

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }
}

# Associate DCR with AKS
resource "azurerm_monitor_data_collection_rule_association" "aks" {
  name                    = "MSPPrometheusAssociation"
  target_resource_id      = var.aks_cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
  description             = "Associates Prometheus DCR with AKS."
}

# ============================================================================
# Diagnostic settings — ship Azure Monitor Workspace metrics to Log Analytics.
# ============================================================================
resource "azurerm_monitor_diagnostic_setting" "monitor_workspace" {
  name                       = "diag-${var.name_suffix}-amw"
  target_resource_id         = azurerm_monitor_workspace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric { category = "AllMetrics" }
}

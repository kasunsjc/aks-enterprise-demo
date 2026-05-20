# ============================================================================
# Azure Monitor Workspace — Managed Prometheus backend.
# Metrics ingested via DCR are stored here and queried by Grafana.
# ============================================================================
resource "azurerm_monitor_workspace" "this" {
  name                          = "amw-${var.name_suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  public_network_access_enabled = false
  tags                          = var.tags
}

# ============================================================================
# Azure Managed Grafana — dashboards with private access only.
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
    resource_id = azurerm_monitor_workspace.this.id
  }
}

# Grafana system identity needs Monitoring Data Reader on the Monitor workspace.
resource "azurerm_role_assignment" "grafana_monitor_reader" {
  scope                = azurerm_monitor_workspace.this.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.this.identity[0].principal_id
}

# ============================================================================
# Private DNS zone — Azure Monitor Workspace (Managed Prometheus).
# Zone name format: privatelink.<region>.prometheus.monitor.azure.com
# ============================================================================
resource "azurerm_private_dns_zone" "prometheus" {
  name                = "privatelink.${var.location}.prometheus.monitor.azure.com"
  resource_group_name = var.hub_resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "prometheus_spoke" {
  name                  = "pdz-link-prometheus-spoke"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.prometheus.name
  virtual_network_id    = var.spoke_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "prometheus_hub" {
  name                  = "pdz-link-prometheus-hub"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.prometheus.name
  virtual_network_id    = var.hub_vnet_id
}

# ============================================================================
# Private DNS zone — Azure Managed Grafana.
# ============================================================================
resource "azurerm_private_dns_zone" "grafana" {
  name                = "privatelink.grafana.azure.com"
  resource_group_name = var.hub_resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "grafana_spoke" {
  name                  = "pdz-link-grafana-spoke"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.grafana.name
  virtual_network_id    = var.spoke_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "grafana_hub" {
  name                  = "pdz-link-grafana-hub"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.grafana.name
  virtual_network_id    = var.hub_vnet_id
}

# ============================================================================
# Private endpoint — Azure Monitor Workspace.
# Subresource "prometheusMetrics" enables private ingestion and query.
# ============================================================================
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
    private_dns_zone_ids = [azurerm_private_dns_zone.prometheus.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.prometheus_spoke]
}

# ============================================================================
# Private endpoint — Azure Managed Grafana.
# ============================================================================
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
    private_dns_zone_ids = [azurerm_private_dns_zone.grafana.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.grafana_spoke]
}

# ============================================================================
# Data Collection Rule (DCR) — scrapes Prometheus metrics from AKS and
# forwards them to the Monitor workspace via the private endpoint.
# ============================================================================
resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                = "dcr-${var.name_suffix}-prometheus"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  description         = "Collects Prometheus metrics from AKS cluster and forwards to Azure Monitor workspace."

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

# Associate the DCR with the AKS cluster to start metric collection.
resource "azurerm_monitor_data_collection_rule_association" "aks" {
  name                    = "MSPPrometheusAssociation"
  target_resource_id      = var.aks_cluster_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
  description             = "Associates Prometheus DCR with the AKS cluster."
}

# ============================================================================
# Submodule: Recording rules
# ============================================================================
module "recording_rules" {
  source = "./modules/recording_rules"

  name_suffix          = var.name_suffix
  resource_group_name  = var.resource_group_name
  location             = var.location
  monitor_workspace_id = azurerm_monitor_workspace.this.id
  tags                 = var.tags
}

# ============================================================================
# Submodule: Alerting rules
# ============================================================================
module "alerting_rules" {
  source = "./modules/alerting_rules"

  name_suffix          = var.name_suffix
  resource_group_name  = var.resource_group_name
  location             = var.location
  monitor_workspace_id = azurerm_monitor_workspace.this.id
  action_group_ids     = var.action_group_ids
  tags                 = var.tags
}

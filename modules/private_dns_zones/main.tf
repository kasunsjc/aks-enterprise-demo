# ============================================================================
# AKS API Server Private DNS Zone
# ============================================================================
resource "azurerm_private_dns_zone" "aks" {
  count               = var.enable_aks_dns_zone ? 1 : 0
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_spoke" {
  count                 = var.enable_aks_dns_zone ? 1 : 0
  name                  = "pdz-link-aks-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = var.spoke_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_hub" {
  count                 = var.enable_aks_dns_zone ? 1 : 0
  name                  = "pdz-link-aks-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = var.hub_vnet_id
}

# ============================================================================
# Prometheus (Managed Prometheus) Private DNS Zone
# ============================================================================
resource "azurerm_private_dns_zone" "prometheus" {
  count               = var.enable_prometheus_dns_zone ? 1 : 0
  name                = "privatelink.${var.location}.prometheus.monitor.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "prometheus_spoke" {
  count                 = var.enable_prometheus_dns_zone ? 1 : 0
  name                  = "pdz-link-prometheus-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.prometheus[0].name
  virtual_network_id    = var.spoke_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "prometheus_hub" {
  count                 = var.enable_prometheus_dns_zone ? 1 : 0
  name                  = "pdz-link-prometheus-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.prometheus[0].name
  virtual_network_id    = var.hub_vnet_id
}

# ============================================================================
# Grafana Private DNS Zone
# ============================================================================
resource "azurerm_private_dns_zone" "grafana" {
  count               = var.enable_grafana_dns_zone ? 1 : 0
  name                = "privatelink.grafana.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "grafana_spoke" {
  count                 = var.enable_grafana_dns_zone ? 1 : 0
  name                  = "pdz-link-grafana-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.grafana[0].name
  virtual_network_id    = var.spoke_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "grafana_hub" {
  count                 = var.enable_grafana_dns_zone ? 1 : 0
  name                  = "pdz-link-grafana-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.grafana[0].name
  virtual_network_id    = var.hub_vnet_id
}

# ============================================================================
# Azure Container Registry Private DNS Zone
# ============================================================================
resource "azurerm_private_dns_zone" "acr" {
  count               = var.enable_acr_dns_zone ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_spoke" {
  count                 = var.enable_acr_dns_zone ? 1 : 0
  name                  = "pdz-link-acr-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.spoke_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_hub" {
  count                 = var.enable_acr_dns_zone ? 1 : 0
  name                  = "pdz-link-acr-hub"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.hub_vnet_id
}

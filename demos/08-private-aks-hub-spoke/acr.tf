# ============================================================================
# Premium Azure Container Registry with private endpoint.
# Public network access is disabled — all pulls go via privatelink.azurecr.io.
# ============================================================================
resource "azurerm_container_registry" "this" {
  name                          = "acr${replace(local.name_suffix, "-", "")}${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.spoke.name
  location                      = azurerm_resource_group.spoke.location
  sku                           = "Premium" # required for private endpoints
  admin_enabled                 = false     # never use admin user in prod
  public_network_access_enabled = false
  tags                          = local.tags
}

# Private DNS zone for ACR (single global name; create once per landing zone).
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_spoke" {
  name                  = "pdz-link-acr-spoke"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_hub" {
  name                  = "pdz-link-acr-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${local.name_suffix}-acr"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  subnet_id           = azurerm_subnet.pe.id
  tags                = local.tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.this.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

# AKS kubelet identity needs AcrPull on the registry to pull images privately.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

# Operator gets AcrPush so they can push images from the jumpbox.
resource "azurerm_role_assignment" "operator_acr_push" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = var.operator_object_id
}

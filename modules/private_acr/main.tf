# ============================================================================
# Premium ACR — public access disabled, all pulls via privatelink.azurecr.io.
# ============================================================================
resource "azurerm_container_registry" "this" {
  name                          = "acr${replace(var.name_suffix, "-", "")}${var.unique_identifier}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium" # private endpoints require Premium SKU
  admin_enabled                 = false     # never use admin credentials in production
  public_network_access_enabled = false
  tags                          = var.tags
}

# ============================================================================
# Private DNS zone for ACR.
# The zone name is a global constant — only one zone per landing zone.
# ============================================================================
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.hub_resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_spoke" {
  name                  = "pdz-link-acr-spoke"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.spoke_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_hub" {
  name                  = "pdz-link-acr-hub"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.hub_vnet_id
}

# ============================================================================
# Private endpoint — attaches ACR to the spoke's PE subnet.
# ============================================================================
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-${var.name_suffix}-acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

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

# ============================================================================
# Role assignments for ACR.
# ============================================================================

# AKS kubelet pulls images; needs AcrPull on the registry.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_object_id
}

# Operator pushes images from the jumpbox.
resource "azurerm_role_assignment" "operator_acr_push" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = var.operator_object_id
}

# Jumpbox MSI also needs AcrPull to `docker pull` / `az acr login` without interactive auth.
resource "azurerm_role_assignment" "jumpbox_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = var.jumpbox_identity_object_id
}

# Windows jumpbox MSI also needs AcrPull to pull images / use `az acr login`.
resource "azurerm_role_assignment" "windows_jumpbox_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = var.windows_jumpbox_identity_object_id
}

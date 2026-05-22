# ============================================================================
# Premium ACR — public access disabled, all pulls via privatelink.azurecr.io.
# ============================================================================
resource "azurerm_container_registry" "this" {
  name                          = "acr${replace(var.name_suffix, "-", "")}${var.unique_identifier}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = var.tags
}

# ============================================================================
# Private endpoint for ACR
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
    private_dns_zone_ids = [var.acr_dns_zone_id]
  }
}

# ============================================================================
# Role assignments for ACR
# ============================================================================
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_object_id
}

resource "azurerm_role_assignment" "operator_acr_push" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = var.operator_object_id
}

# TODO: re-enable when jumpbox is restored
# resource "azurerm_role_assignment" "jumpbox_acr_pull" {
#   scope                = azurerm_container_registry.this.id
#   role_definition_name = "AcrPull"
#   principal_id         = var.jumpbox_identity_object_id
# }

# TODO: re-enable when jumpbox is restored
# resource "azurerm_role_assignment" "windows_jumpbox_acr_pull" {
#   scope                = azurerm_container_registry.this.id
#   role_definition_name = "AcrPull"
#   principal_id         = var.windows_jumpbox_identity_object_id
# }

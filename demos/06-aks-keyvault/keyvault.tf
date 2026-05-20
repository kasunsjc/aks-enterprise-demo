resource "azurerm_key_vault" "this" {
  name                          = "kv${replace(local.name_suffix, "-", "")}${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true # Note: renamed to `rbac_authorization_enabled` in azurerm v5 (current pin: ~> 4.0).
  purge_protection_enabled      = true
  soft_delete_retention_days    = 30
  public_network_access_enabled = true
  tags                          = local.tags
}

# Grant the AKS kubelet identity permission to GET secrets via CSI driver / Workload Identity.
resource "azurerm_role_assignment" "aks_kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

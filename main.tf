locals {
  name_suffix           = "paks-${var.environment}"
  effective_operator_id = var.operator_object_id != "" ? var.operator_object_id : data.azurerm_client_config.current.object_id
  tags = merge(var.tags, {
    environment = var.environment
  })
}

# Resource groups
resource "azurerm_resource_group" "hub" {
  name     = "rg-${local.name_suffix}-hub"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "rg-${local.name_suffix}-spoke"
  location = var.location
  tags     = local.tags
}

module "platform" {
  source = "./modules/platform_stack"

  name_suffix               = local.name_suffix
  hub_resource_group_name   = azurerm_resource_group.hub.name
  spoke_resource_group_name = azurerm_resource_group.spoke.name
  location                  = var.location
  hub_address_space         = var.hub_address_space
  spoke_address_space       = var.spoke_address_space
  hub_subnets               = var.hub_subnets
  spoke_subnets             = var.spoke_subnets
  tags                      = local.tags
}

module "core" {
  source = "./modules/core_stack"

  name_suffix              = local.name_suffix
  unique_identifier        = var.unique_identifier
  hub_resource_group_name  = azurerm_resource_group.hub.name
  spoke_resource_group_name = azurerm_resource_group.spoke.name
  location                 = var.location
  kubernetes_version       = var.kubernetes_version
  aks_subnet_id            = module.platform.aks_subnet_id
  spoke_vnet_id            = module.platform.spoke_vnet_id
  hub_vnet_id              = module.platform.hub_vnet_id
  private_dns_zone_id      = module.platform.aks_dns_zone_id
  tenant_id                = data.azurerm_client_config.current.tenant_id
  operator_object_id       = local.effective_operator_id
  node_resource_group_name = var.node_resource_group_name
  system_node_vm_size      = var.system_node_vm_size
  system_node_min_count    = var.system_node_min_count
  system_node_max_count    = var.system_node_max_count
  log_retention_days       = var.log_retention_days
  tags                     = local.tags

  depends_on = [module.platform]
}

module "addons" {
  source = "./modules/addons_stack"

  name_suffix             = local.name_suffix
  unique_identifier       = var.unique_identifier
  hub_resource_group_name = azurerm_resource_group.hub.name
  spoke_resource_group_name = azurerm_resource_group.spoke.name
  location                = var.location
  pe_subnet_id            = module.platform.pe_subnet_id
  spoke_vnet_id           = module.platform.spoke_vnet_id
  hub_vnet_id             = module.platform.hub_vnet_id
  acr_dns_zone_id         = module.platform.acr_dns_zone_id
  prometheus_dns_zone_id  = module.platform.prometheus_dns_zone_id
  grafana_dns_zone_id     = module.platform.grafana_dns_zone_id
  aks_cluster_id          = module.core.aks_cluster_id
  aks_subnet_id           = module.platform.aks_subnet_id
  aks_kubelet_object_id   = module.core.kubelet_identity_object_id
  operator_object_id      = local.effective_operator_id
  grafana_major_version   = var.grafana_major_version
  action_group_ids        = var.alert_action_group_ids
  node_pools              = var.node_pools
  tags                    = local.tags

  depends_on = [module.core]
}

module "private_aks" {
  source = "../private_aks"

  name_suffix              = var.name_suffix
  unique_identifier        = var.unique_identifier
  resource_group_name      = var.spoke_resource_group_name
  location                 = var.location
  kubernetes_version       = var.kubernetes_version
  aks_subnet_id            = var.aks_subnet_id
  spoke_vnet_id            = var.spoke_vnet_id
  hub_vnet_id              = var.hub_vnet_id
  hub_resource_group_name  = var.hub_resource_group_name
  private_dns_zone_id      = var.private_dns_zone_id
  tenant_id                = var.tenant_id
  operator_object_id       = var.operator_object_id
  node_resource_group_name = var.node_resource_group_name
  system_node_vm_size      = var.system_node_vm_size
  system_node_min_count    = var.system_node_min_count
  system_node_max_count    = var.system_node_max_count
  log_retention_days       = var.log_retention_days
  tags                     = var.tags
}

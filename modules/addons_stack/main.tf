module "private_acr" {
  source = "../private_acr"

  name_suffix                = var.name_suffix
  unique_identifier          = var.unique_identifier
  resource_group_name        = var.spoke_resource_group_name
  location                   = var.location
  pe_subnet_id               = var.pe_subnet_id
  spoke_vnet_id              = var.spoke_vnet_id
  hub_vnet_id                = var.hub_vnet_id
  hub_resource_group_name    = var.hub_resource_group_name
  acr_dns_zone_id            = var.acr_dns_zone_id
  aks_kubelet_object_id      = var.aks_kubelet_object_id
  operator_object_id         = var.operator_object_id
  jumpbox_identity_object_id = var.jumpbox_identity_object_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags
}

module "managed_prometheus" {
  source = "../managed_prometheus"

  name_suffix                = var.name_suffix
  resource_group_name        = var.spoke_resource_group_name
  location                   = var.location
  pe_subnet_id               = var.pe_subnet_id
  aks_cluster_id             = var.aks_cluster_id
  prometheus_dns_zone_id     = var.prometheus_dns_zone_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags
}

module "grafana" {
  source = "../grafana"

  name_suffix                = var.name_suffix
  resource_group_name        = var.spoke_resource_group_name
  location                   = var.location
  grafana_major_version      = tostring(var.grafana_major_version)
  pe_subnet_id               = var.pe_subnet_id
  monitor_workspace_id       = module.managed_prometheus.monitor_workspace_id
  grafana_dns_zone_id        = var.grafana_dns_zone_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = var.tags
}

module "recording_rules" {
  source = "../recording_rules"

  name_suffix          = var.name_suffix
  resource_group_name  = var.spoke_resource_group_name
  location             = var.location
  monitor_workspace_id = module.managed_prometheus.monitor_workspace_id
  tags                 = var.tags
}

module "alerting_rules" {
  source = "../alerting_rules"

  name_suffix          = var.name_suffix
  resource_group_name  = var.spoke_resource_group_name
  location             = var.location
  monitor_workspace_id = module.managed_prometheus.monitor_workspace_id
  action_group_ids     = var.action_group_ids
  tags                 = var.tags
}

module "aks_node_pools" {
  source = "../aks_node_pools"

  kubernetes_cluster_id = var.aks_cluster_id
  aks_subnet_id         = var.aks_subnet_id
  node_pools            = var.node_pools
  tags                  = var.tags
}

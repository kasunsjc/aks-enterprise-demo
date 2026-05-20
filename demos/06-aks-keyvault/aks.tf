resource "azurerm_kubernetes_cluster" "this" {
  name                      = "aks-${local.name_suffix}"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  dns_prefix                = "aks-${local.name_suffix}"
  kubernetes_version        = var.kubernetes_version
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true
  tags                              = local.tags

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    auto_scaling_enabled = true
    min_count            = var.node_count_min
    max_count            = var.node_count_max
    os_disk_size_gb      = 64
    type                 = "VirtualMachineScaleSets"
    only_critical_addons_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.this.id
    msi_auth_for_monitoring_enabled = true
  }
}

# Separate user node pool for workloads (best practice: system vs user pools).
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.node_vm_size
  auto_scaling_enabled  = true
  min_count             = 1
  max_count             = 5
  mode                  = "User"
  os_disk_size_gb       = 128
  tags                  = local.tags
}

# Ship cluster diagnostic logs to Log Analytics.
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "aks-to-law"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

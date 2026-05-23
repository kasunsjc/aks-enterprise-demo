# ============================================================================
# Additional AKS node pools — managed independently of the AKS cluster module.
# The system (default) node pool is created inside the private_aks module at
# cluster-provisioning time. Every pool defined here is an extra user pool that
# can be added, removed, or re-sized without touching the cluster resource.
# ============================================================================
resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = var.node_pools

  name                  = each.key
  kubernetes_cluster_id = var.kubernetes_cluster_id
  vm_size               = each.value.vm_size
  auto_scaling_enabled  = true
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  mode                  = each.value.mode
  vnet_subnet_id        = var.aks_subnet_id
  os_disk_size_gb       = each.value.os_disk_size_gb
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  tags                  = var.tags

  # Explicitly pin upgrade_settings to Azure's defaults to prevent
  # perpetual drift — Azure always writes these fields on create.
  upgrade_settings {
    max_surge                     = "10%"
    drain_timeout_in_minutes      = 0
    node_soak_duration_in_minutes = 0
  }
}

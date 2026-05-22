# ============================================================================
# User-assigned managed identity for the AKS control plane.
# Required when supplying a BYO private DNS zone (system-managed DNS zone
# is not used so AKS needs its own identity to create the A record).
# ============================================================================
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.name_suffix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# AKS needs Private DNS Zone Contributor to create the A record for the API
# server FQDN in the BYO zone at cluster-creation time.
resource "azurerm_role_assignment" "aks_dns_contributor" {
  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# AKS needs Network Contributor on the spoke VNet to manage NIC attachments
# and internal load-balancer / private-link service entries.
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.spoke_vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# ============================================================================
# Log Analytics workspace — used by Container Insights / OMS agent.
# ============================================================================
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_suffix}-${var.unique_identifier}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# ============================================================================
# Private AKS cluster.
# ============================================================================
resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kubernetes_version  = var.kubernetes_version
  dns_prefix          = "aks-${var.name_suffix}"
  node_resource_group = var.node_resource_group_name != "" ? var.node_resource_group_name : "rg-${var.name_suffix}-aks-nodes"
  tags                = var.tags

  private_cluster_enabled             = true
  private_dns_zone_id                 = var.private_dns_zone_id
  private_cluster_public_fqdn_enabled = false

  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    auto_scaling_enabled         = true
    min_count                    = var.system_node_min_count
    max_count                    = var.system_node_max_count
    vnet_subnet_id               = var.aks_subnet_id
    only_critical_addons_enabled = true
    os_disk_size_gb              = 64
    type                         = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge                     = "10%"
      drain_timeout_in_minutes      = 0
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
    outbound_type       = "userDefinedRouting"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = var.tenant_id
  }

  # Enables the AKS Azure Monitor managed service for Prometheus addon (AMA metrics).
  monitor_metrics {}
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.this.id
    msi_auth_for_monitoring_enabled = true
  }

  # RBAC and DNS role assignments must exist before the cluster is created.
  depends_on = [
    azurerm_role_assignment.aks_dns_contributor,
    azurerm_role_assignment.aks_network_contributor,
  ]
}

# Cluster admin role so the operator can run kubectl after get-credentials.
resource "azurerm_role_assignment" "operator_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.operator_object_id
}

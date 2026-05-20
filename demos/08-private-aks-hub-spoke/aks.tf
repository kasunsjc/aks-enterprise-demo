# ============================================================================
# Private DNS zone for AKS API server.
# When private_cluster_enabled = true and we bring our own DNS zone, the zone
# name MUST be exactly:  privatelink.<region>.azmk8s.io
# ============================================================================
resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_spoke" {
  name                  = "pdz-link-aks-spoke"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_hub" {
  name                  = "pdz-link-aks-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

# ============================================================================
# User-assigned managed identity for the AKS control plane.
# Required when bringing our own private DNS zone for the API server.
# ============================================================================
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${local.name_suffix}-aks"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = local.tags
}

# AKS needs Private DNS Zone Contributor on the BYO zone so it can create
# the A record for the API server FQDN at cluster create time.
resource "azurerm_role_assignment" "aks_dns_contributor" {
  scope                = azurerm_private_dns_zone.aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# AKS needs Network Contributor on the spoke VNet to attach NICs and (if used)
# create load balancer / private link service entries.
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.spoke.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# ============================================================================
# Log Analytics workspace (for Container Insights)
# ============================================================================
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name_suffix}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# ============================================================================
# Private AKS cluster
# ============================================================================
resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  kubernetes_version  = var.kubernetes_version
  dns_prefix          = "aks-${local.name_suffix}"
  tags                = local.tags

  # --- Make it private ---
  private_cluster_enabled             = true
  private_dns_zone_id                 = azurerm_private_dns_zone.aks.id
  private_cluster_public_fqdn_enabled = false

  # Egress is forced through Firewall via the UDR on snet-aks.
  # (outbound_type is set inside network_profile below.)

  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true

  default_node_pool {
    name                         = "system"
    vm_size                      = "Standard_D2s_v5"
    auto_scaling_enabled         = true
    min_count                    = 1
    max_count                    = 3
    vnet_subnet_id               = azurerm_subnet.aks.id
    only_critical_addons_enabled = true
    os_disk_size_gb              = 64
    type                         = "VirtualMachineScaleSets"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
    outbound_type       = "userDefinedRouting"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.this.id
    msi_auth_for_monitoring_enabled = true
  }

  # Make sure the RBAC, DNS, and route are in place BEFORE the cluster is
  # created — otherwise AKS provisioning will fail.
  depends_on = [
    azurerm_role_assignment.aks_dns_contributor,
    azurerm_role_assignment.aks_network_contributor,
    azurerm_subnet_route_table_association.aks,
    azurerm_firewall_policy_rule_collection_group.aks,
  ]
}

# User-mode node pool for application workloads.
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = "Standard_D2s_v5"
  auto_scaling_enabled  = true
  min_count             = 1
  max_count             = 5
  mode                  = "User"
  vnet_subnet_id        = azurerm_subnet.aks.id
  os_disk_size_gb       = 128
  tags                  = local.tags
}

# Cluster admin RBAC for the operator (so kubectl works after `az aks get-credentials`).
resource "azurerm_role_assignment" "operator_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.operator_object_id
}

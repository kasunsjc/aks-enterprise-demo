output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL — use this when wiring Workload Identity federated credentials."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "kube_config_command" {
  description = "Command to fetch kubeconfig once apply finishes."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.this.name}"
}

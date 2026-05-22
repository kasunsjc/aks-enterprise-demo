output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "private_fqdn" {
  description = "Private API server FQDN. Resolves to a private IP via the BYO DNS zone."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity. Used for AcrPull assignment."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace used by AKS Container Insights."
  value       = azurerm_log_analytics_workspace.this.id
}

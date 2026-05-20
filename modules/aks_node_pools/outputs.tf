output "node_pool_ids" {
  description = "Map of node pool name → resource ID."
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.this : k => v.id }
}

output "node_pool_names" {
  description = "List of created node pool names."
  value       = keys(azurerm_kubernetes_cluster_node_pool.this)
}

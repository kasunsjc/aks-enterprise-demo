output "resource_group_hub" {
  description = "Hub resource group name."
  value       = azurerm_resource_group.hub.name
}

output "resource_group_spoke" {
  description = "Spoke resource group name."
  value       = azurerm_resource_group.spoke.name
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = module.core.aks_cluster_name
}

output "aks_private_fqdn" {
  description = "Private FQDN of the AKS API server."
  value       = module.core.aks_private_fqdn
}

output "get_credentials_command" {
  description = "Command to get AKS credentials."
  value       = "az aks get-credentials -g ${azurerm_resource_group.spoke.name} -n ${module.core.aks_cluster_name}"
}

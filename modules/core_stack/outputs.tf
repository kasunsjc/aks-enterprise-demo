output "aks_cluster_id" {
  value = module.private_aks.cluster_id
}

output "aks_cluster_name" {
  value = module.private_aks.cluster_name
}

output "aks_private_fqdn" {
  value = module.private_aks.private_fqdn
}

output "kubelet_identity_object_id" {
  value = module.private_aks.kubelet_identity_object_id
}

output "log_analytics_workspace_id" {
  value = module.private_aks.log_analytics_workspace_id
}

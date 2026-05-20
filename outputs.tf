output "hub_resource_group" {
  value = azurerm_resource_group.hub.name
}

output "spoke_resource_group" {
  value = azurerm_resource_group.spoke.name
}

output "aks_cluster_name" {
  value = module.private_aks.cluster_name
}

output "aks_private_fqdn" {
  description = "Private API server FQDN. Resolves to a private IP via the BYO DNS zone."
  value       = module.private_aks.private_fqdn
}

output "acr_login_server" {
  value = module.private_acr.login_server
}

output "firewall_private_ip" {
  description = "Firewall's private IP — next hop for AKS egress."
  value       = module.hub_security.firewall_private_ip
}

output "bastion_name" {
  value = module.hub_security.bastion_name
}

output "jumpbox_name" {
  value = module.jumpbox.vm_name
}

output "windows_jumpbox_name" {
  value = module.windows_jumpbox.vm_name
}

output "next_steps" {
  description = "How to reach the private cluster after apply."
  value       = <<-EOT
    1. Linux jumpbox: open VM '${module.jumpbox.vm_name}' in the Azure portal and Connect via Bastion (SSH).
       Username: ${var.jumpbox_admin_username}
    2. Windows jumpbox: open VM '${module.windows_jumpbox.vm_name}' in the Azure portal and Connect via Bastion (RDP).
       Username: ${var.windows_jumpbox_admin_username}
    3. On either jumpbox:
         az login
         az aks get-credentials -g ${azurerm_resource_group.spoke.name} -n ${module.private_aks.cluster_name}
         kubectl get nodes
    4. To push an image privately:
         az acr login --name ${module.private_acr.acr_name}
         docker push ${module.private_acr.login_server}/<your-image>:tag
    5. Open Grafana (via Bastion/jumpbox, private only):
         ${module.monitoring.grafana_endpoint}
  EOT
}

output "grafana_endpoint" {
  description = "Azure Managed Grafana endpoint (accessible via private endpoint from within the VNet)."
  value       = module.monitoring.grafana_endpoint
}

output "monitor_workspace_id" {
  description = "Azure Monitor workspace resource ID (Managed Prometheus backend)."
  value       = module.monitoring.monitor_workspace_id
}

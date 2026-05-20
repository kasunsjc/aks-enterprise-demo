output "hub_resource_group" {
  value = azurerm_resource_group.hub.name
}

output "spoke_resource_group" {
  value = azurerm_resource_group.spoke.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "aks_private_fqdn" {
  description = "Private API server FQDN. Resolves to a private IP via the BYO DNS zone."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "acr_login_server" {
  value = azurerm_container_registry.this.login_server
}

output "firewall_private_ip" {
  description = "Firewall's private IP — next hop for AKS egress."
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "bastion_name" {
  value = azurerm_bastion_host.hub.name
}

output "jumpbox_name" {
  value = azurerm_linux_virtual_machine.jumpbox.name
}

output "next_steps" {
  description = "How to reach the private cluster after apply."
  value       = <<-EOT
    1. In the Azure portal, open VM '${azurerm_linux_virtual_machine.jumpbox.name}' and Connect via Bastion.
       Username: ${var.jumpbox_admin_username}
    2. On the jumpbox:
         az login
         az aks get-credentials -g ${azurerm_resource_group.spoke.name} -n ${azurerm_kubernetes_cluster.this.name}
         kubectl get nodes
    3. To push an image privately:
         az acr login --name ${azurerm_container_registry.this.name}
         docker push ${azurerm_container_registry.this.login_server}/<your-image>:tag
  EOT
}

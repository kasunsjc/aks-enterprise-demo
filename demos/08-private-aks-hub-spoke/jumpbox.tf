# ============================================================================
# Linux jumpbox — no public IP. Reached via Bastion only.
# Has Azure CLI + kubectl pre-installed via cloud-init.
# ============================================================================
resource "azurerm_network_interface" "jumpbox" {
  name                = "nic-${local.name_suffix}-jumpbox"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = local.tags

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.jumpbox.id
    private_ip_address_allocation = "Dynamic"
  }
}

locals {
  jumpbox_cloud_init = <<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - curl
      - ca-certificates
      - gnupg
      - apt-transport-https
    runcmd:
      - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
      - curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
      - echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
      - apt-get update
      - apt-get install -y kubectl
  CLOUDINIT
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                            = "vm-${local.name_suffix}-jumpbox"
  resource_group_name             = azurerm_resource_group.spoke.name
  location                        = azurerm_resource_group.spoke.location
  size                            = var.jumpbox_vm_size
  admin_username                  = var.jumpbox_admin_username
  admin_password                  = var.jumpbox_admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.jumpbox.id]
  tags                            = local.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = base64encode(local.jumpbox_cloud_init)
}

# Let the jumpbox identity read the AKS cluster (so `az aks get-credentials`
# works without further role assignments from the operator).
resource "azurerm_role_assignment" "jumpbox_aks_user" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_linux_virtual_machine.jumpbox.identity[0].principal_id
}

resource "azurerm_role_assignment" "jumpbox_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_virtual_machine.jumpbox.identity[0].principal_id
}

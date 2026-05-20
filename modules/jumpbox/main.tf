locals {
  cloud_init = <<-CLOUDINIT
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

# ============================================================================
# Jumpbox — no public IP; reachable only through Azure Bastion.
# cloud-init installs Azure CLI and kubectl on first boot.
# ============================================================================
resource "azurerm_network_interface" "jumpbox" {
  name                = "nic-${var.name_suffix}-jumpbox"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = var.jumpbox_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                            = "vm-${var.name_suffix}-jumpbox"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.jumpbox.id]
  tags                            = var.tags

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

  custom_data = base64encode(local.cloud_init)
}

# ============================================================================
# Role assignments for the jumpbox system-assigned managed identity.
# ============================================================================

# Allows `az aks get-credentials` without needing the operator's personal token.
resource "azurerm_role_assignment" "jumpbox_aks_user" {
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_linux_virtual_machine.jumpbox.identity[0].principal_id
}


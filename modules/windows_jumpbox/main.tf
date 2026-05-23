locals {
  # Bootstrap PowerShell: installs Chocolatey, then Azure CLI, kubectl, kubelogin, Helm, git, Docker CLI, and Headlamp.
  # kubelogin is installed via choco (not az aks install-cli) to avoid PATH
  # refresh issues when az is freshly installed in the same process session.
  bootstrap_script = <<-PS1
    $ErrorActionPreference = 'Stop'
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (-not (Test-Path "$env:ProgramData\\chocolatey\\bin\\choco.exe")) {
      iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    & "$env:ProgramData\\chocolatey\\bin\\choco.exe" install -y azure-cli kubernetes-cli kubelogin kubernetes-helm git docker-cli headlamp --no-progress
  PS1
}

# ============================================================================
# Windows Jumpbox — no public IP; reachable only through Azure Bastion (RDP).
# A Custom Script Extension installs Azure CLI, kubectl, kubelogin, Helm, git, Docker CLI,
# and Headlamp on
# first boot via Chocolatey.
# ============================================================================
resource "azurerm_network_interface" "windows_jumpbox" {
  name                = "nic-${var.name_suffix}-wjumpbox"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = var.jumpbox_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "windows_jumpbox" {
  # Azure Windows VM names are limited to 15 characters.
  name                  = substr("vmw-${var.name_suffix}", 0, 15)
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.windows_jumpbox.id]
  tags                  = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Custom Script Extension: installs Azure CLI, kubectl, Helm, git, Docker CLI, and Headlamp via Chocolatey.
resource "azurerm_virtual_machine_extension" "bootstrap" {
  name                       = "bootstrap"
  virtual_machine_id         = azurerm_windows_virtual_machine.windows_jumpbox.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  protected_settings = jsonencode({
    commandToExecute = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(local.bootstrap_script, "UTF-16LE")}"
  })
}

# ============================================================================
# Role assignments for the Windows jumpbox system-assigned managed identity.
# ============================================================================

# Allows `az aks get-credentials` without requiring the operator's personal token.
resource "azurerm_role_assignment" "aks_user" {
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_windows_virtual_machine.windows_jumpbox.identity[0].principal_id
}

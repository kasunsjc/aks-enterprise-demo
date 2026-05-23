locals {
  # ── Default images ─────────────────────────────────────────────────────────
  default_linux_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  default_windows_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  effective_image = var.image_reference != null ? var.image_reference : (
    var.os_type == "linux" ? local.default_linux_image : local.default_windows_image
  )

  # ── Default cloud-init (Linux) ──────────────────────────────────────────────
  default_cloud_init = <<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - curl
      - ca-certificates
      - gnupg
      - apt-transport-https
      - docker.io
      - snapd
    runcmd:
      - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
      - curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
      - echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
      - apt-get update
      - apt-get install -y kubectl
      - az aks install-cli --kubelogin --kubelogin-install-location /usr/local/bin/kubelogin
      - snap install helm --classic
      - snap install k9s --classic
      - systemctl enable docker
      - systemctl start docker
      - usermod -aG docker ${var.admin_username}
  CLOUDINIT

  # Caller may supply pre-encoded custom_data; otherwise encode the default.
  effective_custom_data = var.os_type == "linux" ? (
    var.custom_data != null ? var.custom_data : base64encode(local.default_cloud_init)
  ) : null

  # ── Default bootstrap script (Windows) ─────────────────────────────────────
  default_bootstrap_script = <<-PS1
    $ErrorActionPreference = 'Stop'
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (-not (Test-Path "$env:ProgramData\\chocolatey\\bin\\choco.exe")) {
      iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    & "$env:ProgramData\\chocolatey\\bin\\choco.exe" install -y azure-cli kubernetes-cli kubelogin kubernetes-helm git docker-cli headlamp --no-progress
  PS1

  effective_bootstrap_script = var.os_type == "windows" ? (
    var.bootstrap_script != null ? var.bootstrap_script : local.default_bootstrap_script
  ) : null

  # Resolved principal ID regardless of OS type.
  vm_principal_id = var.os_type == "linux" ? (
    azurerm_linux_virtual_machine.jumpbox[0].identity[0].principal_id
    ) : (
    azurerm_windows_virtual_machine.jumpbox[0].identity[0].principal_id
  )
}

# ============================================================================
# Shared NIC — no public IP; reachable only through Azure Bastion.
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

# ============================================================================
# Linux VM — cloud-init installs Azure CLI, kubectl, kubelogin, Helm, k9s, Docker.
# ============================================================================
resource "azurerm_linux_virtual_machine" "jumpbox" {
  count = var.os_type == "linux" ? 1 : 0

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
    publisher = local.effective_image.publisher
    offer     = local.effective_image.offer
    sku       = local.effective_image.sku
    version   = local.effective_image.version
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = local.effective_custom_data
}

# ============================================================================
# Windows VM — Custom Script Extension installs toolchain via Chocolatey.
# ============================================================================
resource "azurerm_windows_virtual_machine" "jumpbox" {
  count = var.os_type == "windows" ? 1 : 0

  # Azure Windows VM names are limited to 15 characters.
  name                  = substr("vm-${var.name_suffix}", 0, 15)
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.jumpbox.id]
  tags                  = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = local.effective_image.publisher
    offer     = local.effective_image.offer
    sku       = local.effective_image.sku
    version   = local.effective_image.version
  }

  identity {
    type = "SystemAssigned"
  }
}

# Tracks the script hash — forces extension replacement when the script changes.
resource "terraform_data" "bootstrap_version" {
  count = var.os_type == "windows" ? 1 : 0
  input = sha256(local.effective_bootstrap_script)
}

resource "azurerm_virtual_machine_extension" "bootstrap" {
  count = var.os_type == "windows" ? 1 : 0

  name                       = "bootstrap"
  virtual_machine_id         = azurerm_windows_virtual_machine.jumpbox[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  protected_settings = jsonencode({
    commandToExecute = "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(local.effective_bootstrap_script, "UTF-16LE")}"
  })

  lifecycle {
    replace_triggered_by = [terraform_data.bootstrap_version[0]]
  }
}

# ============================================================================
# Role assignment — jumpbox MSI gets AKS Cluster User role.
# ============================================================================
resource "azurerm_role_assignment" "jumpbox_aks_user" {
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = local.vm_principal_id
}

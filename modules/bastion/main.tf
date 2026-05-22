# ============================================================================
# Azure Bastion — browser-based SSH/RDP with no VM public IPs required.
# Standard SKU enables tunneling so `az network bastion tunnel` works too.
# ============================================================================
resource "azurerm_public_ip" "bastion" {
  name                = "pip-${var.name_suffix}-bastion"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = "bas-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tunneling_enabled   = true
  copy_paste_enabled  = true
  tags                = var.tags

  ip_configuration {
    name                 = "ipcfg"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

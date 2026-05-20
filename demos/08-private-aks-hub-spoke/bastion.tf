# ============================================================================
# Azure Bastion in the hub — operators reach private resources via the browser
# ============================================================================
resource "azurerm_public_ip" "bastion" {
  name                = "pip-${local.name_suffix}-bastion"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_bastion_host" "hub" {
  name                = "bas-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku                 = "Standard"
  tags                = local.tags

  # Standard SKU enables tunneling (az network bastion tunnel) and copy/paste,
  # so engineers can `kubectl` from their laptop via a tunnel as well.
  tunneling_enabled  = true
  copy_paste_enabled = true

  ip_configuration {
    name                 = "ipcfg"
    subnet_id            = azurerm_subnet.hub_bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

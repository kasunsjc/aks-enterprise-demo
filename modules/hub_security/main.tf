# ============================================================================
# Azure Firewall + Firewall Policy with AKS-required egress rules.
# Reference: https://learn.microsoft.com/azure/aks/limit-egress-traffic
# ============================================================================
resource "azurerm_public_ip" "firewall" {
  name                = "pip-${var.name_suffix}-fw"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "hub" {
  name                = "afwp-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "hub" {
  name                = "afw-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  tags                = var.tags

  ip_configuration {
    name                 = "ipcfg"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "aks" {
  name               = "rcg-aks"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 200

  # --- Network rules (IP / service-tag based) ---
  network_rule_collection {
    name     = "aks-network"
    priority = 400
    action   = "Allow"

    rule {
      name                  = "aks-tunnel-tcp-9000"
      protocols             = ["TCP"]
      source_addresses      = [var.aks_node_cidr]
      destination_addresses = ["AzureCloud.${var.location_shortcode}"]
      destination_ports     = ["9000"]
    }

    rule {
      name                  = "aks-tunnel-udp-1194"
      protocols             = ["UDP"]
      source_addresses      = [var.aks_node_cidr]
      destination_addresses = ["AzureCloud.${var.location_shortcode}"]
      destination_ports     = ["1194"]
    }

    rule {
      name                  = "ntp"
      protocols             = ["UDP"]
      source_addresses      = [var.aks_node_cidr]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    rule {
      name             = "azure-services-443"
      protocols        = ["TCP"]
      source_addresses = [var.aks_node_cidr]
      destination_addresses = [
        "AzureCloud.${var.location_shortcode}",
        "AzureMonitor",
        "MicrosoftContainerRegistry",
      ]
      destination_ports = ["443"]
    }
  }

  # --- Application rules (FQDN-based HTTPS) ---
  application_rule_collection {
    name     = "aks-application"
    priority = 500
    action   = "Allow"

    # Microsoft-published FQDN tag covers the full official AKS required list.
    rule {
      name                  = "aks-fqdn-tag"
      source_addresses      = [var.aks_node_cidr]
      destination_fqdn_tags = ["AzureKubernetesService"]
    }

    # Extra FQDNs: image pulls, OS packages, monitoring.
    rule {
      name             = "container-images-and-os-updates"
      source_addresses = [var.aks_node_cidr]

      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "*.cdn.mscr.io",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net",
        "management.azure.com",
        "login.microsoftonline.com",
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com",
      ]
    }
  }
}

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

resource "azurerm_bastion_host" "hub" {
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

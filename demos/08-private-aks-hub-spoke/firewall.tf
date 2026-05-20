# ============================================================================
# Azure Firewall in the hub + policy with AKS-required egress
# ============================================================================
resource "azurerm_public_ip" "firewall" {
  name                = "pip-${local.name_suffix}-fw"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_firewall_policy" "hub" {
  name                = "afwp-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_firewall" "hub" {
  name                = "afw-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  tags                = local.tags

  ip_configuration {
    name                 = "ipcfg"
    subnet_id            = azurerm_subnet.hub_firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# ----------------------------------------------------------------------------
# Firewall policy rules: required egress for AKS.
# Reference: https://learn.microsoft.com/azure/aks/limit-egress-traffic
# ----------------------------------------------------------------------------
resource "azurerm_firewall_policy_rule_collection_group" "aks" {
  name               = "rcg-aks"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 200

  # --- Network rules (TCP/UDP, IP/service-tag based) ---
  network_rule_collection {
    name     = "aks-network"
    priority = 400
    action   = "Allow"

    rule {
      name                  = "aks-tunnel-tcp-9000"
      protocols             = ["TCP"]
      source_addresses      = [var.spoke_subnets.aks]
      destination_addresses = ["AzureCloud.${var.location}"]
      destination_ports     = ["9000"]
    }

    rule {
      name                  = "aks-tunnel-udp-1194"
      protocols             = ["UDP"]
      source_addresses      = [var.spoke_subnets.aks]
      destination_addresses = ["AzureCloud.${var.location}"]
      destination_ports     = ["1194"]
    }

    rule {
      name                  = "ntp"
      protocols             = ["UDP"]
      source_addresses      = [var.spoke_subnets.aks]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    rule {
      name             = "azure-services-443"
      protocols        = ["TCP"]
      source_addresses = [var.spoke_subnets.aks]
      destination_addresses = [
        "AzureCloud.${var.location}",
        "AzureMonitor",
        "MicrosoftContainerRegistry",
      ]
      destination_ports = ["443"]
    }
  }

  # --- Application rules (HTTPS, FQDN-based) ---
  application_rule_collection {
    name     = "aks-application"
    priority = 500
    action   = "Allow"

    # Microsoft-published FQDN tag covers the full official AKS list.
    rule {
      name                  = "aks-fqdn-tag"
      source_addresses      = [var.spoke_subnets.aks]
      destination_fqdn_tags = ["AzureKubernetesService"]
    }

    # Extra commonly-needed FQDNs for image pulls, OS updates, monitoring.
    rule {
      name             = "container-images-and-os-updates"
      source_addresses = [var.spoke_subnets.aks]

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

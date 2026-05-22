module "hub_network" {
  source = "../hub_network"

  name_suffix          = var.name_suffix
  resource_group_name  = var.hub_resource_group_name
  location             = var.location
  address_space        = var.hub_address_space
  subnet_cidr_firewall = var.hub_subnets.firewall
  subnet_cidr_bastion  = var.hub_subnets.bastion
  subnet_cidr_shared   = var.hub_subnets.shared
  tags                 = var.tags
}

module "firewall" {
  source = "../firewall"

  name_suffix         = var.name_suffix
  resource_group_name = var.hub_resource_group_name
  location            = var.location
  firewall_subnet_id  = module.hub_network.firewall_subnet_id
  aks_node_cidr       = var.spoke_subnets.aks
  location_shortcode  = var.location
  tags                = var.tags
}

module "bastion" {
  source = "../bastion"

  name_suffix         = var.name_suffix
  resource_group_name = var.hub_resource_group_name
  location            = var.location
  bastion_subnet_id   = module.hub_network.bastion_subnet_id
  tags                = var.tags
}

module "spoke_network" {
  source = "../spoke_network"

  name_suffix             = var.name_suffix
  resource_group_name     = var.spoke_resource_group_name
  location                = var.location
  address_space           = var.spoke_address_space
  subnet_cidr_aks         = var.spoke_subnets.aks
  subnet_cidr_pe          = var.spoke_subnets.pe
  subnet_cidr_jumpbox     = var.spoke_subnets.jumpbox
  hub_vnet_id             = module.hub_network.vnet_id
  hub_vnet_name           = module.hub_network.vnet_name
  hub_resource_group_name = var.hub_resource_group_name
  firewall_private_ip     = module.firewall.firewall_private_ip
  tags                    = var.tags
}

module "private_dns_zones" {
  source = "../private_dns_zones"

  resource_group_name = var.hub_resource_group_name
  location            = var.location
  spoke_vnet_id       = module.spoke_network.vnet_id
  hub_vnet_id         = module.hub_network.vnet_id

  enable_aks_dns_zone        = true
  enable_prometheus_dns_zone = true
  enable_grafana_dns_zone    = true
  enable_acr_dns_zone        = true

  tags = var.tags
}

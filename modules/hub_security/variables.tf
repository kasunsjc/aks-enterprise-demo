variable "name_suffix" {
  description = "Suffix used in every resource name in the hub security tier."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds hub security resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "firewall_subnet_id" {
  description = "Resource ID of AzureFirewallSubnet in the hub VNet."
  type        = string
}

variable "bastion_subnet_id" {
  description = "Resource ID of AzureBastionSubnet in the hub VNet."
  type        = string
}

variable "aks_node_cidr" {
  description = "CIDR of the AKS node subnet in the spoke. Used as source in firewall rules."
  type        = string
}

variable "location_shortcode" {
  description = "Azure region used in service-tag suffixes (e.g. 'eastus'). Must match var.location."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

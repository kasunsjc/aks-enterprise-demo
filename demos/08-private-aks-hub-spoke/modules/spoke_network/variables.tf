variable "name_suffix" {
  description = "Suffix used in every resource name in the spoke (e.g. 'paks-dev')."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds spoke network resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "Address space for the spoke VNet."
  type        = list(string)
}

variable "subnet_cidr_aks" {
  description = "CIDR for the AKS node subnet."
  type        = string
}

variable "subnet_cidr_pe" {
  description = "CIDR for the private-endpoint subnet."
  type        = string
}

variable "subnet_cidr_jumpbox" {
  description = "CIDR for the jumpbox subnet."
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet (for peering)."
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet (for peering)."
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group of the hub VNet (needed for hub→spoke peering)."
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP of the Azure Firewall. Used as next-hop in the AKS UDR."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

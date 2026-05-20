variable "name_suffix" {
  description = "Suffix used in every resource name in the hub (e.g. 'paks-dev')."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that will hold hub network resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "Address space for the hub VNet."
  type        = list(string)
}

variable "subnet_cidr_firewall" {
  description = "CIDR for AzureFirewallSubnet (must be at least /26)."
  type        = string
}

variable "subnet_cidr_bastion" {
  description = "CIDR for AzureBastionSubnet (must be at least /26 for Standard SKU)."
  type        = string
}

variable "subnet_cidr_shared" {
  description = "CIDR for the general-purpose shared subnet."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

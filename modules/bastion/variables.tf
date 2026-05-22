variable "name_suffix" {
  description = "Suffix used in every resource name (e.g. 'paks-dev')."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the Bastion host and its public IP."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "bastion_subnet_id" {
  description = "Resource ID of AzureBastionSubnet in the hub VNet."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

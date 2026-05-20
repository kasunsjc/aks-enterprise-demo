variable "name" {
  description = "Spoke VNet name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the spoke."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "Spoke address space (must not overlap with the hub or other spokes)."
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnet name => CIDR."
  type        = map(string)
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet to peer with."
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet (used to create the reverse peering)."
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group that holds the hub (for reverse peering)."
  type        = string
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}

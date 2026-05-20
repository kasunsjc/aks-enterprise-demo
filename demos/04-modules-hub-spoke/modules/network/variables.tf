variable "name" {
  description = "Hub VNet name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the hub."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "Address space for the hub VNet (CIDRs)."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "address_space must contain at least one CIDR block."
  }
}

variable "subnets" {
  description = "Map of subnet name => CIDR for the hub."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default     = {}
}

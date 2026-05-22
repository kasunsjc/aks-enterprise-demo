variable "name_suffix" {
  type = string
}

variable "hub_resource_group_name" {
  type = string
}

variable "spoke_resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "hub_address_space" {
  type = list(string)
}

variable "spoke_address_space" {
  type = list(string)
}

variable "hub_subnets" {
  type = object({
    firewall = string
    bastion  = string
    shared   = string
  })
}

variable "spoke_subnets" {
  type = object({
    aks     = string
    pe      = string
    jumpbox = string
  })
}

variable "log_retention_days" {
  description = "Retention period (days) for the hub Log Analytics workspace."
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "hub_address_space" {
  description = "Hub VNet CIDRs."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "hub_subnets" {
  description = "Hub subnets."
  type        = map(string)
  default = {
    shared   = "10.0.1.0/24"
    bastion  = "10.0.2.0/27" # AzureBastionSubnet sized
    firewall = "10.0.3.0/26"
  }
}

variable "spokes" {
  description = "Map of spoke name => spoke definition."
  type = map(object({
    address_space = list(string)
    subnets       = map(string)
  }))
  default = {
    app = {
      address_space = ["10.10.0.0/16"]
      subnets = {
        web = "10.10.1.0/24"
        api = "10.10.2.0/24"
      }
    }
    data = {
      address_space = ["10.20.0.0/16"]
      subnets = {
        sql   = "10.20.1.0/24"
        cache = "10.20.2.0/24"
      }
    }
  }
}

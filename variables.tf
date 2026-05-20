variable "environment" {
  description = "Environment name (e.g., dev, prod). Used in resource naming."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.environment))
    error_message = "environment must be 2-8 lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "hub_address_space" {
  description = "Hub VNet address space."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke_address_space" {
  description = "Spoke VNet address space."
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "hub_subnets" {
  description = "CIDRs for hub subnets. Names are fixed (Azure requires AzureFirewallSubnet and AzureBastionSubnet)."
  type = object({
    firewall = string
    bastion  = string
    shared   = string
  })
  default = {
    firewall = "10.0.1.0/26" # AzureFirewallSubnet (min /26)
    bastion  = "10.0.2.0/26" # AzureBastionSubnet (min /26 for Standard)
    shared   = "10.0.3.0/24"
  }
}

variable "spoke_subnets" {
  description = "CIDRs for spoke subnets."
  type = object({
    aks     = string
    pe      = string
    jumpbox = string
  })
  default = {
    aks     = "10.10.1.0/24"
    pe      = "10.10.2.0/24"
    jumpbox = "10.10.3.0/27"
  }
}

variable "jumpbox_vm_size" {
  description = "Size of the jumpbox VM."
  type        = string
  default     = "Standard_B2s"
}

variable "jumpbox_admin_username" {
  description = "Admin username on the jumpbox VM."
  type        = string
  default     = "azureadmin"
}

variable "jumpbox_admin_password" {
  description = "Admin password on the jumpbox VM. Use a strong password; this is sensitive."
  type        = string
  sensitive   = true
}

variable "operator_object_id" {
  description = "AAD object ID for the operator/admin user (gets cluster admin + ACR Push)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    workload   = "private-aks-landing-zone"
    managed_by = "terraform"
  }
}

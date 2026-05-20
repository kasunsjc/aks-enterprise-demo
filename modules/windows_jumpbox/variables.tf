variable "name_suffix" {
  description = "Suffix used in every resource name (e.g. 'paks-dev')."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds Windows jumpbox resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "jumpbox_subnet_id" {
  description = "Resource ID of the jumpbox subnet."
  type        = string
}

variable "vm_size" {
  description = "VM size for the Windows jumpbox."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "Admin username for the Windows jumpbox VM."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Admin password for the Windows jumpbox VM."
  type        = string
  sensitive   = true
}

variable "aks_cluster_id" {
  description = "Resource ID of the AKS cluster (Windows jumpbox MSI granted Cluster User role)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

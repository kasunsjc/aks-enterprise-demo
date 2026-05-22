variable "name_suffix" {
  description = "Suffix used in every resource name."
  type        = string
}

variable "unique_identifier" {
  description = "Short identifier for globally-unique names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for ACR."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "pe_subnet_id" {
  description = "Private endpoint subnet ID."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Spoke VNet ID."
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet ID."
  type        = string
}

variable "hub_resource_group_name" {
  description = "Hub resource group name."
  type        = string
}

variable "acr_dns_zone_id" {
  description = "ACR private DNS zone ID (from private_dns_zones module)."
  type        = string
}

variable "aks_kubelet_object_id" {
  description = "Object ID of AKS kubelet identity (granted AcrPull)."
  type        = string
}

variable "operator_object_id" {
  description = "AAD object ID of operator (granted AcrPush)."
  type        = string
}

variable "jumpbox_identity_object_id" {
  description = "Object ID of Linux jumpbox system-assigned identity."
  type        = string
  default     = ""
}

variable "windows_jumpbox_identity_object_id" {
  description = "Object ID of Windows jumpbox system-assigned identity."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

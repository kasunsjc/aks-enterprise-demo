variable "name_suffix" {
  description = "Suffix used in every resource name (e.g. 'paks-dev')."
  type        = string
}

variable "unique_identifier" {
  description = "Short identifier appended to globally-unique resource names (ACR). Should match the root module's unique_identifier."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds ACR and its private endpoint."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "pe_subnet_id" {
  description = "Resource ID of the private-endpoint subnet."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet (for DNS zone link)."
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet (for DNS zone link)."
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group in which the ACR private DNS zone is created."
  type        = string
}

variable "aks_kubelet_object_id" {
  description = "Object ID of the AKS kubelet managed identity (granted AcrPull)."
  type        = string
}

variable "operator_object_id" {
  description = "Object ID of the operator (granted AcrPush)."
  type        = string
}

variable "jumpbox_identity_object_id" {
  description = "Object ID of the Linux jumpbox system-assigned identity (granted AcrPull)."
  type        = string
}

variable "windows_jumpbox_identity_object_id" {
  description = "Object ID of the Windows jumpbox system-assigned identity (granted AcrPull)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

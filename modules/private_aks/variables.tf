variable "name_suffix" {
  description = "Suffix used in every resource name (e.g. 'paks-dev')."
  type        = string
}

variable "random_suffix" {
  description = "Short random string appended to globally-unique resources (Log Analytics)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds AKS and related resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "aks_subnet_id" {
  description = "Resource ID of the AKS node subnet."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet (used for DNS zone link)."
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet (used for DNS zone link)."
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group that holds the hub (DNS zones are created there to be shared)."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "operator_object_id" {
  description = "Object ID of the operator; granted AKS RBAC Cluster Admin."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

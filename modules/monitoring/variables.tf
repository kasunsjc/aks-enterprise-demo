variable "name_suffix" {
  description = "Suffix used in every resource name (e.g. 'paks-dev')."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for monitoring resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "aks_cluster_id" {
  description = "Resource ID of the AKS cluster to monitor."
  type        = string
}

variable "pe_subnet_id" {
  description = "Resource ID of the private-endpoint subnet."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet for private DNS zone links."
  type        = string
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet for private DNS zone links."
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group that holds shared hub resources (DNS zones are created here)."
  type        = string
}

variable "action_group_ids" {
  description = "List of Azure Monitor action group IDs to notify on alerts."
  type        = list(string)
  default     = []
}

variable "grafana_major_version" {
  description = "Major version of Managed Grafana to deploy (9 or 10)."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags applied to all monitoring resources."
  type        = map(string)
  default     = {}
}

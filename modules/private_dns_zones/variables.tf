variable "resource_group_name" {
  description = "Hub resource group that holds DNS zones."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "spoke_vnet_id" {
  description = "Spoke VNet ID (for DNS zone links)."
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet ID (for DNS zone links)."
  type        = string
}

variable "enable_aks_dns_zone" {
  description = "Create private DNS zone for AKS API server."
  type        = bool
  default     = true
}

variable "enable_prometheus_dns_zone" {
  description = "Create private DNS zone for Prometheus."
  type        = bool
  default     = false
}

variable "enable_grafana_dns_zone" {
  description = "Create private DNS zone for Grafana."
  type        = bool
  default     = false
}

variable "enable_acr_dns_zone" {
  description = "Create private DNS zone for Container Registry."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

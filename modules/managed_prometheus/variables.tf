variable "name_suffix" {
  description = "Suffix used in every resource name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds Prometheus resources."
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

variable "aks_cluster_id" {
  description = "AKS cluster ID (for DCR association)."
  type        = string
}

variable "prometheus_dns_zone_id" {
  description = "Prometheus private DNS zone ID (from private_dns_zones module)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

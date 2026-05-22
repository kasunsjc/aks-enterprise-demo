variable "name_suffix" {
  description = "Suffix used in every resource name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds Grafana resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "grafana_major_version" {
  description = "Grafana major version."
  type        = string
  default     = "10"
}

variable "pe_subnet_id" {
  description = "Private endpoint subnet ID."
  type        = string
}

variable "monitor_workspace_id" {
  description = "Azure Monitor Workspace ID (for integration)."
  type        = string
}

variable "grafana_dns_zone_id" {
  description = "Grafana private DNS zone ID (from private_dns_zones module)."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace for Grafana diagnostic logs."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

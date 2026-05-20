variable "name_suffix" {
  description = "Suffix used in resource names."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the rule group resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "monitor_workspace_id" {
  description = "Resource ID of the Azure Monitor workspace (Managed Prometheus backend)."
  type        = string
}

variable "action_group_ids" {
  description = "List of Azure Monitor action group IDs to notify on alerts. Leave empty to create rules without notifications."
  type        = list(string)
  default     = []
}

variable "interval" {
  description = "Evaluation interval for alerting rules (ISO 8601 duration)."
  type        = string
  default     = "PT1M"
}

variable "tags" {
  description = "Tags applied to rule group resources."
  type        = map(string)
  default     = {}
}

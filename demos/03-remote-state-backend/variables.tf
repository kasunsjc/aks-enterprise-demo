variable "environment" {
  description = "Short environment name (e.g., dev, stage, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod", "shared"], var.environment)
    error_message = "environment must be one of: dev, stage, prod, shared."
  }
}

variable "location" {
  description = "Azure region for the state backend."
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Tags applied to all platform resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
    component  = "tfstate-backend"
    layer      = "platform"
  }
}

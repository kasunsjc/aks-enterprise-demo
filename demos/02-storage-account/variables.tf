variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed."
  type        = string
}

variable "storage_account_prefix" {
  description = "Prefix for storage account names (3-10 lowercase chars recommended)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.storage_account_prefix))
    error_message = "storage_account_prefix must be 3-10 lowercase alphanumeric characters."
  }
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    environment = "demo"
    managed_by  = "terraform"
    project     = "terraform-azure-learning"
  }
}

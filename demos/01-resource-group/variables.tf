variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed."
  type        = string
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

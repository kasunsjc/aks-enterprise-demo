variable "environment" {
  description = "Environment name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "admin_object_id" {
  description = "AAD object ID that will be granted admin RBAC on Key Vault (e.g. your user)."
  type        = string
}

variable "address_space" {
  description = "VNet CIDR."
  type        = list(string)
  default     = ["10.40.0.0/16"]
}

variable "app_subnet_cidr" {
  description = "Subnet CIDR delegated to App Service VNet integration."
  type        = string
  default     = "10.40.1.0/24"
}

variable "pe_subnet_cidr" {
  description = "Subnet CIDR for private endpoints."
  type        = string
  default     = "10.40.2.0/24"
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default = {
    workload   = "secure-webapp-sql"
    managed_by = "terraform"
  }
}

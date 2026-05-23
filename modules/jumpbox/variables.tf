variable "name_suffix" {
  description = "Suffix used in every resource name (e.g. 'paks-dev')."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds jumpbox resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "jumpbox_subnet_id" {
  description = "Resource ID of the jumpbox subnet."
  type        = string
}

variable "os_type" {
  description = "Operating system type for the jumpbox VM: 'linux' or 'windows'."
  type        = string
  default     = "linux"

  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "os_type must be 'linux' or 'windows'."
  }
}

variable "vm_size" {
  description = "VM size for the jumpbox."
  type        = string
  default     = "Standard_B2s"
}

variable "image_reference" {
  description = <<-EOT
    Source image for the jumpbox VM. When null, a sensible default is used based on os_type:
    - linux   → Canonical Ubuntu 22.04 LTS Gen2
    - windows → Microsoft Windows Server 2022 Datacenter Gen2
  EOT
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}

variable "custom_data" {
  description = <<-EOT
    Base64-encoded cloud-init payload (Linux only). When null, a default script that
    installs Azure CLI, kubectl, kubelogin, Helm, k9s, and Docker is used.
    Ignored when os_type = 'windows'.
  EOT
  type        = string
  default     = null
}

variable "bootstrap_script" {
  description = <<-EOT
    PowerShell bootstrap script (Windows only). When null, a default Chocolatey-based
    script that installs Azure CLI, kubectl, kubelogin, Helm, git, Docker CLI, and
    Headlamp is used. Ignored when os_type = 'linux'.
  EOT
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Admin username for the jumpbox VM."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Admin password for the jumpbox VM."
  type        = string
  sensitive   = true
}

variable "aks_cluster_id" {
  description = "Resource ID of the AKS cluster (jumpbox MSI granted Cluster User role)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "kubernetes_cluster_id" {
  description = "Resource ID of the AKS cluster to attach node pools to."
  type        = string
}

variable "aks_subnet_id" {
  description = "Resource ID of the subnet for node VMs."
  type        = string
}

variable "node_pools" {
  description = <<-EOT
    Map of user node pools to create. The map key becomes the node pool name
    (max 12 lowercase alphanumeric characters — AKS restriction).
    Example:
      node_pools = {
        user = { vm_size = "Standard_D4s_v5", min_count = 1, max_count = 5 }
      }
  EOT
  type = map(object({
    vm_size         = string
    min_count       = number
    max_count       = number
    os_disk_size_gb = optional(number, 128)
    mode            = optional(string, "User")
    node_labels     = optional(map(string), {})
    node_taints     = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, _ in var.node_pools : can(regex("^[a-z][a-z0-9]{0,11}$", k))
    ])
    error_message = "Node pool names must be 1-12 lowercase alphanumeric characters starting with a letter."
  }
}

variable "tags" {
  description = "Tags applied to all node pool resources."
  type        = map(string)
  default     = {}
}

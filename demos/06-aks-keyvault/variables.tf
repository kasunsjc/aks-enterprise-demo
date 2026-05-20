variable "environment" {
  description = "Environment (dev, stage, prod)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "node_count_min" {
  description = "Minimum node count for the default node pool."
  type        = number
  default     = 1
}

variable "node_count_max" {
  description = "Maximum node count for the default node pool."
  type        = number
  default     = 3
}

variable "node_vm_size" {
  description = "VM size for AKS nodes."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "tags" {
  description = "Tags."
  type        = map(string)
  default = {
    workload   = "aks-platform"
    managed_by = "terraform"
  }
}

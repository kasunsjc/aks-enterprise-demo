variable "name_suffix" {
  type = string
}

variable "unique_identifier" {
  type = string
}

variable "hub_resource_group_name" {
  type = string
}

variable "spoke_resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "pe_subnet_id" {
  type = string
}

variable "spoke_vnet_id" {
  type = string
}

variable "hub_vnet_id" {
  type = string
}

variable "acr_dns_zone_id" {
  type = string
}

variable "prometheus_dns_zone_id" {
  type = string
}

variable "grafana_dns_zone_id" {
  type = string
}

variable "aks_cluster_id" {
  type = string
}

variable "aks_subnet_id" {
  type = string
}

variable "aks_kubelet_object_id" {
  type = string
}

variable "operator_object_id" {
  type = string
}

variable "grafana_major_version" {
  type = number
}

variable "action_group_ids" {
  type    = list(string)
  default = []
}

variable "node_pools" {
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
}

variable "tags" {
  type    = map(string)
  default = {}
}

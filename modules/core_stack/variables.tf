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

variable "kubernetes_version" {
  type = string
}

variable "aks_subnet_id" {
  type = string
}

variable "spoke_vnet_id" {
  type = string
}

variable "hub_vnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "operator_object_id" {
  type = string
}

variable "node_resource_group_name" {
  type = string
}

variable "system_node_vm_size" {
  type = string
}

variable "system_node_min_count" {
  type = number
}

variable "system_node_max_count" {
  type = number
}

variable "log_retention_days" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}

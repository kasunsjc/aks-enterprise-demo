# ============================================================================
# Prometheus Recording Rules — Node level
# These pre-aggregate expensive node metrics so dashboards stay fast.
# ============================================================================
resource "azurerm_monitor_alert_prometheus_rule_group" "node_rules" {
  name                = "recording-node-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  rule_group_enabled  = true
  interval            = var.interval
  scopes              = [var.monitor_workspace_id]
  tags                = var.tags

  rule {
    enabled    = true
    record     = "instance:node_cpu_utilisation:rate5m"
    expression = "1 - avg by(instance)(rate(node_cpu_seconds_total{mode=\"idle\"}[5m]))"
    labels     = { source = "aks-managed-prometheus" }
  }

  rule {
    enabled    = true
    record     = "instance:node_memory_utilisation:ratio"
    expression = "1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)"
    labels     = { source = "aks-managed-prometheus" }
  }

  rule {
    enabled    = true
    record     = "instance:node_disk_utilisation:ratio"
    expression = "1 - (node_filesystem_avail_bytes{mountpoint=\"/\",fstype!=\"tmpfs\"} / node_filesystem_size_bytes{mountpoint=\"/\",fstype!=\"tmpfs\"})"
    labels     = { source = "aks-managed-prometheus" }
  }

  rule {
    enabled    = true
    record     = "instance:node_network_receive_bytes:rate5m"
    expression = "rate(node_network_receive_bytes_total{device!~\"lo|docker.*|veth.*|br.*|flannel.*|cbr.*|cni.*|tunl.*\"}[5m])"
    labels     = { source = "aks-managed-prometheus" }
  }

  rule {
    enabled    = true
    record     = "instance:node_network_transmit_bytes:rate5m"
    expression = "rate(node_network_transmit_bytes_total{device!~\"lo|docker.*|veth.*|br.*|flannel.*|cbr.*|cni.*|tunl.*\"}[5m])"
    labels     = { source = "aks-managed-prometheus" }
  }
}

# ============================================================================
# Prometheus Recording Rules — Container / workload level
# ============================================================================
resource "azurerm_monitor_alert_prometheus_rule_group" "container_rules" {
  name                = "recording-container-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  rule_group_enabled  = true
  interval            = var.interval
  scopes              = [var.monitor_workspace_id]
  tags                = var.tags

  rule {
    enabled    = true
    record     = "namespace_pod_container:container_cpu_usage_seconds_total:sum_rate5m"
    expression = "sum by(namespace, pod, container)(rate(container_cpu_usage_seconds_total{image!=\"\",container!=\"\"}[5m]))"
    labels     = { source = "aks-managed-prometheus" }
  }

  rule {
    enabled    = true
    record     = "namespace_pod_container:container_memory_working_set_bytes:sum"
    expression = "sum by(namespace, pod, container)(container_memory_working_set_bytes{image!=\"\",container!=\"\"})"
    labels     = { source = "aks-managed-prometheus" }
  }

  rule {
    enabled    = true
    record     = "namespace_workload:kube_pod_owner:relabel"
    expression = <<-PROMQL
      max by(namespace, workload, pod)(
        label_replace(
          label_replace(
            kube_pod_owner{owner_kind="ReplicaSet"},
            "replicaset", "$1", "owner_name", "(.*)"
          ) * on(replicaset, namespace) group_left(owner_name)
            kube_replicaset_owner{},
          "workload", "$1", "owner_name", "(.*)"
        )
      )
    PROMQL
    labels = { source = "aks-managed-prometheus" }
  }

  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_container_resource_requests:sum"
    expression = "sum by(namespace, pod)(kube_pod_container_resource_requests{resource=\"memory\",container!=\"\"})"
    labels     = { source = "aks-managed-prometheus" }
  }
}

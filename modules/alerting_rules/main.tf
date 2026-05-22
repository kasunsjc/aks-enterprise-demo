# ============================================================================
# Prometheus Alerting Rules — Kubernetes control-plane / workload health
# ============================================================================
resource "azurerm_monitor_alert_prometheus_rule_group" "kube_rules" {
  name                = "alerting-kube-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  rule_group_enabled  = true
  interval            = var.interval
  scopes              = [var.monitor_workspace_id]
  tags                = var.tags

  rule {
    enabled    = true
    alert      = "KubeNodeNotReady"
    expression = "kube_node_status_condition{status=\"true\",condition=\"Ready\"} == 0"
    for        = "PT5M"
    severity   = 2
    labels     = { severity = "warning", team = "platform" }
    annotations = {
      summary     = "Kubernetes node is not ready."
      description = "Node {{ $labels.node }} has been in a non-ready state for more than 5 minutes."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }

  rule {
    enabled    = true
    alert      = "KubePodCrashLooping"
    expression = "rate(kube_pod_container_status_restarts_total[15m]) * 60 > 5"
    for        = "PT15M"
    severity   = 2
    labels     = { severity = "warning", team = "platform" }
    annotations = {
      summary     = "Pod is crash looping."
      description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) is restarting {{ printf \"%.2f\" $value }} times per minute."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }

  rule {
    enabled    = true
    alert      = "KubePodNotReady"
    expression = "sum by(namespace, pod)(max by(namespace, pod)(kube_pod_status_phase{phase=~\"Pending|Unknown\",namespace!~\"kube-system|gatekeeper-system\"})) > 0"
    for        = "PT15M"
    severity   = 2
    labels     = { severity = "warning", team = "platform" }
    annotations = {
      summary     = "Pod has been in a non-ready state."
      description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready state for more than 15 minutes."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }

  rule {
    enabled    = true
    alert      = "KubeContainerWaiting"
    expression = "sum by(namespace, pod, container)(kube_pod_container_status_waiting_reason{reason!~\"ContainerCreating|PodInitializing\",namespace!~\"kube-system\"}) > 0"
    for        = "PT1H"
    severity   = 3
    labels     = { severity = "info", team = "platform" }
    annotations = {
      summary     = "Pod container is waiting."
      description = "Pod {{ $labels.namespace }}/{{ $labels.pod }} container {{ $labels.container }} has been in a waiting state for more than 1 hour."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }

  rule {
    enabled    = true
    alert      = "KubeHpaReplicasMismatch"
    expression = "(kube_horizontalpodautoscaler_status_desired_replicas != kube_horizontalpodautoscaler_status_current_replicas) and changes(kube_horizontalpodautoscaler_status_current_replicas[10m]) == 0"
    for        = "PT10M"
    severity   = 2
    labels     = { severity = "warning", team = "platform" }
    annotations = {
      summary     = "HPA has not matched desired number of replicas."
      description = "HPA {{ $labels.namespace }}/{{ $labels.horizontalpodautoscaler }} has not matched the desired number of replicas for more than 10 minutes."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }

  rule {
    enabled    = true
    alert      = "KubePersistentVolumeFillingUp"
    expression = "kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes < 0.1 and kubelet_volume_stats_capacity_bytes > 0"
    for        = "PT1M"
    severity   = 1
    labels     = { severity = "critical", team = "platform" }
    annotations = {
      summary     = "Persistent volume is filling up."
      description = "PersistentVolume {{ $labels.persistentvolumeclaim }} in namespace {{ $labels.namespace }} is less than 10% free."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }
}

# ============================================================================
# Prometheus Alerting Rules — Node resource pressure
# ============================================================================
resource "azurerm_monitor_alert_prometheus_rule_group" "node_rules" {
  name                = "alerting-node-${var.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  rule_group_enabled  = true
  interval            = var.interval
  scopes              = [var.monitor_workspace_id]
  tags                = var.tags

  rule {
    enabled    = true
    alert      = "KubeNodeMemoryPressure"
    expression = "kube_node_status_condition{condition=\"MemoryPressure\",status=\"true\"} == 1"
    for        = "PT5M"
    severity   = 2
    labels     = { severity = "warning", team = "platform" }
    annotations = {
      summary     = "Node is experiencing memory pressure."
      description = "Node {{ $labels.node }} has MemoryPressure condition active for more than 5 minutes."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }

  rule {
    enabled    = true
    alert      = "KubeNodeDiskPressure"
    expression = "kube_node_status_condition{condition=\"DiskPressure\",status=\"true\"} == 1"
    for        = "PT5M"
    severity   = 2
    labels     = { severity = "warning", team = "platform" }
    annotations = {
      summary     = "Node is experiencing disk pressure."
      description = "Node {{ $labels.node }} has DiskPressure condition active for more than 5 minutes."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }

  rule {
    enabled    = true
    alert      = "NodeHighCpuUtilisation"
    expression = "instance:node_cpu_utilisation:rate5m > 0.9"
    for        = "PT10M"
    severity   = 2
    labels     = { severity = "warning", team = "platform" }
    annotations = {
      summary     = "Node CPU utilisation is high."
      description = "Node {{ $labels.instance }} CPU utilisation has been above 90% for more than 10 minutes."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }

  rule {
    enabled    = true
    alert      = "NodeHighMemoryUtilisation"
    expression = "instance:node_memory_utilisation:ratio > 0.9"
    for        = "PT10M"
    severity   = 2
    labels     = { severity = "warning", team = "platform" }
    annotations = {
      summary     = "Node memory utilisation is high."
      description = "Node {{ $labels.instance }} memory utilisation has been above 90% for more than 10 minutes."
    }

    dynamic "action" {
      for_each = var.action_group_ids
      content {
        action_group_id = action.value
      }
    }
  }
}

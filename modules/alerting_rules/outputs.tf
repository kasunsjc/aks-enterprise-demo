output "kube_rule_group_id" {
  description = "Resource ID of the Kubernetes alerting rule group."
  value       = azurerm_monitor_alert_prometheus_rule_group.kube_rules.id
}

output "node_rule_group_id" {
  description = "Resource ID of the node alerting rule group."
  value       = azurerm_monitor_alert_prometheus_rule_group.node_rules.id
}

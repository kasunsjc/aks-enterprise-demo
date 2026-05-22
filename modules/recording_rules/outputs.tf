output "node_rule_group_id" {
  description = "Resource ID of the node recording rule group."
  value       = azurerm_monitor_alert_prometheus_rule_group.node_rules.id
}

output "container_rule_group_id" {
  description = "Resource ID of the container recording rule group."
  value       = azurerm_monitor_alert_prometheus_rule_group.container_rules.id
}

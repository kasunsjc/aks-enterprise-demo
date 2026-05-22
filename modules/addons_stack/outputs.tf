output "acr_name" {
  value = module.private_acr.acr_name
}

output "monitor_workspace_id" {
  value = module.managed_prometheus.monitor_workspace_id
}

output "grafana_endpoint" {
  value = module.grafana.grafana_endpoint
}

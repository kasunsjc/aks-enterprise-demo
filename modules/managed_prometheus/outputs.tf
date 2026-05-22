output "monitor_workspace_id" {
  description = "Azure Monitor Workspace ID."
  value       = azurerm_monitor_workspace.this.id
}

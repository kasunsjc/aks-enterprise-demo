output "vm_name" {
  description = "Name of the Windows jumpbox VM."
  value       = azurerm_windows_virtual_machine.windows_jumpbox.name
}

output "identity_object_id" {
  description = "Object ID of the Windows jumpbox system-assigned managed identity."
  value       = azurerm_windows_virtual_machine.windows_jumpbox.identity[0].principal_id
}

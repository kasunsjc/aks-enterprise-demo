output "vm_name" {
  description = "Name of the jumpbox VM."
  value       = azurerm_linux_virtual_machine.jumpbox.name
}

output "identity_object_id" {
  description = "Object ID of the jumpbox system-assigned managed identity."
  value       = azurerm_linux_virtual_machine.jumpbox.identity[0].principal_id
}

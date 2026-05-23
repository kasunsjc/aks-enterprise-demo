output "vm_name" {
  description = "Name of the jumpbox VM."
  value = var.os_type == "linux" ? (
    azurerm_linux_virtual_machine.jumpbox[0].name
    ) : (
    azurerm_windows_virtual_machine.jumpbox[0].name
  )
}

output "identity_object_id" {
  description = "Object ID of the jumpbox system-assigned managed identity."
  value = var.os_type == "linux" ? (
    azurerm_linux_virtual_machine.jumpbox[0].identity[0].principal_id
    ) : (
    azurerm_windows_virtual_machine.jumpbox[0].identity[0].principal_id
  )
}

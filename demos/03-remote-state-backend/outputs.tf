output "resource_group_name" {
  description = "Resource group hosting the Terraform state backend."
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Storage account name to use in azurerm backend blocks."
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Blob container that holds Terraform state files."
  value       = azurerm_storage_container.state.name
}

output "backend_config_example" {
  description = "Copy/paste backend snippet for downstream configurations."
  value       = <<-EOT
    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.state.name}"
        storage_account_name = "${azurerm_storage_account.state.name}"
        container_name       = "${azurerm_storage_container.state.name}"
        key                  = "<project>/${var.environment}.tfstate"
      }
    }
  EOT
}

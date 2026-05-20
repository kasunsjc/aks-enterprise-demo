terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "app" {
  source = "../../modules/app"

  app_name         = "demo"
  environment      = "prod"
  location         = "eastus"
  service_plan_sku = "P1v3" # production SKU with VNet integration support
  worker_count     = 3      # baseline horizontal capacity
  https_only       = true

  tags = {
    cost_center = "engineering"
    data_class  = "confidential"
    backup      = "required"
    pager_team  = "demo-app-oncall"
  }
}

output "web_app_url" {
  value = "https://${module.app.web_app_default_hostname}"
}

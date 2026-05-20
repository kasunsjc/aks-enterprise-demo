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
  environment      = "dev"
  location         = "eastus"
  service_plan_sku = "B1"
  worker_count     = 1

  tags = {
    cost_center = "engineering"
  }
}

output "web_app_url" {
  value = "https://${module.app.web_app_default_hostname}"
}

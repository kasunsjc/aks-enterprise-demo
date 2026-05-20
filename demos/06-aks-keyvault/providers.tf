terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Enterprise default: do NOT purge soft-deleted vaults on destroy.
      # Operators may need to recover secrets after an accidental destroy.
      purge_soft_delete_on_destroy = false
    }
  }
}

data "azurerm_client_config" "current" {}

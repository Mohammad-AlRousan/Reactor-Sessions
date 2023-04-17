terraform {
  backend "azurerm" {
    resource_group_name  = "devopsrousan-tfstate-rg"
    storage_account_name = "devopsrousantfgoxdvvmc"
    container_name       = "c-tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

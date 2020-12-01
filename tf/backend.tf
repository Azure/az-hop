terraform {
  backend "azurerm" {
    resource_group_name   = "tfstate-westeurope"
    storage_account_name  = "tfstate1765"
    container_name        = "tfstate"
    key                   = "deploy11988"
  }
}

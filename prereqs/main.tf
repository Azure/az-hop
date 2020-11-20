provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "deployhpc" {
  name     = "hugo-tf-resources"
  location = "westeurope"
}

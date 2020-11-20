provider "azurerm" {
  features {}
}

resource "random_string" "random" {
  length = 8
  special = false
}

resource "azurerm_resource_group" "deployhpc" {
  name     = "hugo-tf-resources"
  location = "westeurope"
}

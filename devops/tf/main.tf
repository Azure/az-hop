provider "azurerm" {
  features {}
}

data "azurerm_subscription" "primary" {}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group
  location = var.location
}

resource "random_string" "resource_postfix" {
  length = 8
  special = false
  upper = false
  lower = true
  number = true
}


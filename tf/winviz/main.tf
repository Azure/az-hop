terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.81.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.13"
}


provider "azurerm" {
  features {}
}

data "azurerm_subscription" "primary" {}

data "azurerm_resource_group" "rg" {
  name     = local.resource_group
}


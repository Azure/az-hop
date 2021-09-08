terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.61.0"
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

data "azurerm_resource_group" "rg" {
  count    = local.create_rg ? 0 : 1
  name     = local.resource_group
}


resource "azurerm_resource_group" "rg" {
  count    = local.create_rg ? 1 : 0
  name     = local.resource_group
  location = local.location
  tags = {
    CreatedBy = var.CreatedBy
    CreatedOn = var.CreatedOn
  }
}


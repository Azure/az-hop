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

data "azurerm_subscription" "primary" {}
data "azurerm_client_config" "current" {}

resource "random_string" "resource_postfix" {
  length = 8
  special = false
  upper = false
  lower = true
  number = true  
}

resource "random_password" "password" {
  length            = 16
  special           = true
  min_lower         = 1
  min_upper         = 1
  min_numeric       = 1
  override_special  = "_%@"
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

resource "tls_private_key" "internal" {
  algorithm = "RSA"
  rsa_bits  = 2048 # This is the default
}

resource "local_file" "private_key" {
    content     = tls_private_key.internal.private_key_pem
    filename = "${path.cwd}/${local.admin_username}_id_rsa"
    file_permission = "0600"
}

resource "local_file" "public_key" {
    content     = tls_private_key.internal.public_key_openssh
    filename = "${path.cwd}/${local.admin_username}_id_rsa.pub"
    file_permission = "0644"
}

# Storage account used for
#   - CycleCloud projects
#   - Terraform states
resource "azurerm_storage_account" "azhop" {
  name                     = "azhop${random_string.resource_postfix.result}"
  resource_group_name      = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location                 = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# create a container for the lustre archive if not using an existing account
resource "azurerm_storage_container" "lustre_archive" {
  count                 = (local.lustre_archive_account == null ? 1 : 0)
  name                  = "lustre"
  storage_account_name  = azurerm_storage_account.azhop.name
  container_access_type = "private"
}

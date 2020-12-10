provider "azurerm" {
  features {}
}

resource "random_string" "random" {
  length = 8
  special = false
}

resource "random_string" "resource_postfix" {
  length = 6
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

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

resource "tls_private_key" "internal" {
  algorithm = "RSA"
  rsa_bits  = 2048 # This is the default
}

resource "local_file" "private_key" {
    content     = tls_private_key.internal.private_key_pem
    filename = "${path.root}/../${var.admin_username}_id_rsa"
    file_permission = "0600"
}

resource "local_file" "public_key" {
    content     = tls_private_key.internal.public_key_openssh
    filename = "${path.root}/../${var.admin_username}_id_rsa.pub"
    file_permission = "0644"
}

# Storage account used for
#   - CycleCloud projects
#   - Terraform states
resource "azurerm_storage_account" "deployhpc" {
  name                      = "storage${random_string.resource_postfix.result}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
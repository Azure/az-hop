terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.35.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.3.0"
    }
  }
  required_version = ">= 0.13"
}


provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_subscription" "primary" {}
# azurerm_client_config is empty when using a managed identity https://github.com/hashicorp/terraform-provider-azurerm/issues/7787
# using variables instead filled up by the build.sh script
#data "azurerm_client_config" "current" {}

resource "random_string" "resource_postfix" {
  length = 8
  special = false
  upper = false
  lower = true
  numeric = true
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

  tags = merge( local.common_tags, local.extra_tags)

  lifecycle {
    ignore_changes = [
      tags
    ]
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
    name                     = local.storage_account_name
    resource_group_name      = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
    location                 = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    min_tls_version          = "TLS1_2"

  # Grant acccess only from the admin and compute subnets
  dynamic "network_rules" {
    for_each = local.locked_down_network ? [1] : []
    content {
      default_action             = "Deny"
      ip_rules                   = local.grant_access_from
      virtual_network_subnet_ids = [local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id,
                                    local.create_compute_subnet ? azurerm_subnet.compute[0].id : data.azurerm_subnet.compute[0].id]
    }
  }
}

# This is the azhop telemetry deployment that is only created if telemetry is enabled.
# It is deployed to the resource group
resource "azurerm_resource_group_template_deployment" "telemetry_azhop" {
    count            = local.optout_telemetry ? 0 : 1
    provider         = azurerm
    name             = local.telem_azhop_name
    resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
    deployment_mode = "Incremental"
    template_content = local.telem_arm_subscription_template_content
}
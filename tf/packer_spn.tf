provider "azuread" {
}

locals {
  spn_name = "deployhpc${random_string.resource_postfix.result}"
}

# Create an application for packer
resource "azuread_application" "packer" {
  name              = local.spn_name
  identifier_uris   = ["http://${local.spn_name}"]
}

resource "random_uuid" "guid" { }

# Create a random password for this application
resource "azuread_application_password" "packer_password" {
  application_object_id  = azuread_application.packer.id
  value                  = random_uuid.guid.result
  end_date_relative      = "8760h" # 1 year
}

# Keep secret in keyvault under secret name == app name
resource "azurerm_key_vault_secret" "packer_password" {
  name         = azuread_application.packer.name
  value        = azuread_application_password.packer_password.value
  key_vault_id = azurerm_key_vault.deployhpc.id
}

# Create a service principal
resource "azuread_service_principal" "packer_spn" {
  application_id = azuread_application.packer.application_id
}

# Assign the role Contributor to the packer SPN on the subscription
# resource "azurerm_role_assignment" "packer_sub_contributor" {
#   scope                = data.azurerm_subscription.primary.id
#   role_definition_name = "Contributor"
#   principal_id         = azuread_service_principal.packer_spn.id
# }

# Assign the role Owner to the packer SPN on the resource group
resource "azurerm_role_assignment" "packer_rg_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.packer_spn.id
}

# Assign the role reader to the packer SPN on the subscription
# resource "azurerm_role_assignment" "packer_reader" {
#   scope                = data.azurerm_subscription.primary.id
#   role_definition_name = "Reader"
#   principal_id         = azuread_service_principal.packer_spn.id
# }

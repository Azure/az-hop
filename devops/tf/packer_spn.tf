provider "azuread" {
}

# locals {
#   #spn_name = try(var.devops_spn, "devops${random_string.resource_postfix.result}")
#   spn_name = var.devops_spn
# }

# Create an application for devops
# If using a SPN to deploy your resources, make sure to grant the right permissions like explained in the documentation
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/guides/service_principal_configuration
resource "azuread_application" "devops" {
  name              = var.devops_spn
  identifier_uris   = ["http://${var.devops_spn}"]
}

resource "random_uuid" "guid" { }

# Create a random password for this application
resource "azuread_application_password" "devops_password" {
  application_object_id  = azuread_application.devops.id
  value                  = random_uuid.guid.result
  end_date_relative      = "8760h" # 1 year
}

# Keep secret in keyvault under secret name == app name
resource "azurerm_key_vault_secret" "devops_password" {
  name         = azuread_application.devops.name
  value        = azuread_application_password.devops_password.value
  key_vault_id = azurerm_key_vault.keyvault.id
}

# Create a service principal
resource "azuread_service_principal" "devops_spn" {
  application_id = azuread_application.devops.application_id
}

# Assign the role Contributor to the devops SPN on the subscription
resource "azurerm_role_assignment" "devops_sub_contributor" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.devops_spn.id
}

# Assign the role "User Access Administrator" to the devops SPN on the subscription so that it can set the managed identity for Cycle.
resource "azurerm_role_assignment" "devops_sub_user_access" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.devops_spn.id
}

# Assign the role Owner to the devops SPN on the resource group so we can use packer
resource "azurerm_role_assignment" "devops_rg_contributor" {
  scope                = azurerm_resource_group.resource_group.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.devops_spn.id
} 


# Assign the role reader to the devops SPN on the subscription
# resource "azurerm_role_assignment" "devops_reader" {
#   scope                = data.azurerm_subscription.primary.id
#   role_definition_name = "Reader"
#   principal_id         = azuread_service_principal.devops_spn.id
# }

resource "local_file" "packer" {
  content = templatefile("${path.root}/../../packer/templates/options.tmpl",
    {
      subscription_id = data.azurerm_subscription.primary.subscription_id
      spn_name = azuread_application.devops.name
      resource_group  = var.resource_group
      key_vault = azurerm_key_vault.keyvault.name
    }
  )
  filename = "${path.module}/../../packer/options.json"
}

output "application" {
  value = azuread_application.devops
}

output "password" {
  value = azuread_application_password.devops_password
}

output "tenandid" {
  value = data.azurerm_subscription.primary.tenant_id
}
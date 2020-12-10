resource "local_file" "packer" {
  content = templatefile("${path.root}/../../packer/templates/spn.json.tmpl",
    {
      spn_name = azuread_application.devops.name
      key_vault = azurerm_key_vault.keyvault.name
    }
  )
  filename = "${path.module}/../../packer/spn.json"
}


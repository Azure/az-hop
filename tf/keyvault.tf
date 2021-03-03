data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "azhop" {
  name                        = format("%s%s", "kv", random_string.resource_postfix.result)
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  # TODO => Add the option to enable VMs to keep secrets in KV
  sku_name = "standard"

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_access_policy" "admin" {
  key_vault_id = azurerm_key_vault.azhop.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
      "get",
      "set",
      "list",
      "delete",
      "purge",
      "recover",
      "restore"
    ]
}

resource "azurerm_key_vault_access_policy" "get_secret" {

  key_vault_id = azurerm_key_vault.azhop.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = local.key_vault_readers != null ? local.key_vault_readers : data.azurerm_client_config.current.object_id

  secret_permissions = [
    "get"
  ]
}
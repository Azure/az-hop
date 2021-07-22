resource "time_sleep" "delay_create" {
  depends_on   = [azurerm_key_vault_access_policy.admin] # As policies are created in the same deployment add some delays to propagate
  create_duration = "20s"
}

resource "azurerm_key_vault" "azhop" {
  name                        = format("%s%s", "kv", random_string.resource_postfix.result)
  location                    = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name         = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
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

# Only create the reader access policy when the key_vault_reader is set
resource "azurerm_key_vault_access_policy" "reader" {
  count = local.key_vault_readers != null ? 1 : 0
  key_vault_id = azurerm_key_vault.azhop.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = local.key_vault_readers != null ? local.key_vault_readers : data.azurerm_client_config.current.object_id

  secret_permissions = [
      "get",
      "list"
    ]
}

resource "azurerm_key_vault_secret" "admin_password" {
  depends_on   = [time_sleep.delay_create, azurerm_key_vault_access_policy.admin] # As policies are created in the same deployment add some delays to propagate
  name         = format("%s-password", local.admin_username)
  value        = random_password.password.result
  key_vault_id = azurerm_key_vault.azhop.id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
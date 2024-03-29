resource "time_sleep" "delay_create" {
  depends_on   = [azurerm_key_vault_access_policy.admin] # As policies are created in the same deployment add some delays to propagate
  create_duration = "20s"
}

resource "azurerm_key_vault" "azhop" {
  name                        = local.key_vault_name
  location                    = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name         = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  enabled_for_disk_encryption = true
  enabled_for_deployment      = true
  enabled_for_template_deployment = true
  tenant_id                   = local.tenant_id
  # soft delete is enabled by default now (2021-8-25), with 90 days retention
  # soft_delete_enabled         = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  # TODO => Add the option to enable VMs to keep secrets in KV
  sku_name = "standard"

  network_acls {
    default_action             = local.locked_down_network ? "Deny" : "Allow"
    bypass                     = "AzureServices"
    ip_rules                   = local.grant_access_from
    virtual_network_subnet_ids = [local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id]
  }
}

resource "azurerm_key_vault_access_policy" "admin" {
  key_vault_id = azurerm_key_vault.azhop.id
  tenant_id    = local.tenant_id
  object_id    = local.logged_user_objectId

  secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete",
      "Purge",
      "Recover",
      "Restore"
    ]
}

# Only create the reader access policy when the key_vault_reader is set
resource "azurerm_key_vault_access_policy" "reader" {
  count = local.key_vault_readers != null ? 1 : 0
  key_vault_id = azurerm_key_vault.azhop.id
  tenant_id    = local.tenant_id
  object_id    = local.key_vault_readers != null ? local.key_vault_readers : local.logged_user_objectId

  secret_permissions = [
      "Get",
      "List"
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

#adding a domain join user secret. If the customer doesn't bring their own AD then this will be the same as the admin password.
resource "azurerm_key_vault_secret" "domain_join_password" {
  count        = local.use_existing_ad ? 1 : 0
  depends_on   = [time_sleep.delay_create, azurerm_key_vault_access_policy.admin] # As policies are created in the same deployment add some delays to propagate
  name         = format("%s-password", local.domain_join_user)
  value        = local.create_ad ? random_password.password.result : local.domain_join_password 
  key_vault_id = azurerm_key_vault.azhop.id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "azurerm_key_vault_secret" "admin_ssh_private" {
  depends_on   = [time_sleep.delay_create, azurerm_key_vault_access_policy.admin]
  name         = format("%s-private", local.admin_username)
  value        = tls_private_key.internal.private_key_pem
  key_vault_id = azurerm_key_vault.azhop.id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "azurerm_key_vault_secret" "admin_ssh_public" {
  depends_on   = [time_sleep.delay_create, azurerm_key_vault_access_policy.admin] 
  name         = format("%s-public", local.admin_username)
  value        = tls_private_key.internal.public_key_openssh
  key_vault_id = azurerm_key_vault.azhop.id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

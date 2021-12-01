resource "azurerm_mysql_flexible_server" "slurmdb" {
  name                = "azhop-slurmdb-${random_string.resource_postfix.result}"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  administrator_login    = "sqladmin"
  administrator_password = random_password.slurmdb_password.result

  sku_name   = "B_Standard_B1ms"
  version    = "5.7"

  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false

  delegated_subnet_id = azurerm_subnet.slurmdb[0].id
  #private_dns_zone_id = azurerm_private_dns_zone.azhop-privatednszone.id
}

resource "azurerm_mysql_flexible_server_configuration" "slurmdb" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_mysql_flexible_server.slurmdb.resource_group_name
  server_name         = azurerm_mysql_flexible_server.slurmdb.name
  value               = "OFF"
}

resource "random_password" "slurmdb_password" {
  length            = 16
  special           = true
  min_lower         = 1
  min_upper         = 1
  min_numeric       = 1
  override_special  = "_%@"
}

resource "azurerm_key_vault_secret" "slurmdb_password" {
  depends_on   = [time_sleep.delay_create, azurerm_key_vault_access_policy.admin] # As policies are created in the same deployment add some delays to propagate
  name         = format("%s-password", azurerm_mysql_flexible_server.slurmdb.administrator_login)
  value        = random_password.slurmdb_password.result
  key_vault_id = azurerm_key_vault.azhop.id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "azurerm_mariadb_server" "mysql" {
  count               = local.slurm_accounting ? 1 : 0
  name                = "azhop-${random_string.resource_postfix.result}"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  administrator_login          = local.slurm_accounting_admin_user
  administrator_login_password = random_password.mysql_password[0].result

  sku_name   = "GP_Gen5_2"
  version    = "10.3"

  backup_retention_days             = 21
  geo_redundant_backup_enabled      = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = false # Enforce to be false because Guacamole 1.4.0 with MariaDB doesn't support SSL. Need to upgrade to 1.5.0 
  auto_grow_enabled                 = true
  storage_mb                        = 5120
}

resource "azurerm_mariadb_virtual_network_rule" "mysql_admin" {
  count               = local.slurm_accounting ? 1 : 0
  name                = "AllowAccessAdmin"
  resource_group_name = azurerm_mariadb_server.mysql[0].resource_group_name
  server_name         = azurerm_mariadb_server.mysql[0].name
  subnet_id           = local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
}

resource "azurerm_mariadb_virtual_network_rule" "mysql_frontend" {
  count               = local.slurm_accounting ? 1 : 0
  name                = "AllowAccessFrontend"
  resource_group_name = azurerm_mariadb_server.mysql[0].resource_group_name
  server_name         = azurerm_mariadb_server.mysql[0].name
  subnet_id           = local.create_frontend_subnet ? azurerm_subnet.frontend[0].id : data.azurerm_subnet.frontend[0].id
}

resource "random_password" "mysql_password" {
  count             = local.slurm_accounting ? 1 : 0
  length            = 16
  special           = false
  min_lower         = 1
  min_upper         = 1
  min_numeric       = 1
}

resource "azurerm_key_vault_secret" "mysql_password" {
  count        = local.slurm_accounting ? 1 : 0
  depends_on   = [time_sleep.delay_create, azurerm_key_vault_access_policy.admin] # As policies are created in the same deployment add some delays to propagate
  name         = format("%s-password", azurerm_mariadb_server.mysql[0].administrator_login)
  value        = random_password.mysql_password[0].result
  key_vault_id = azurerm_key_vault.azhop.id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

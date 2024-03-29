resource "azurerm_mysql_flexible_server" "mysql" {
  count               = local.create_database ? 1 : 0
  name                = local.db_name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  administrator_login          = local.create_database ? local.database_user : ""
  administrator_password       = random_password.db_password[0].result

  delegated_subnet_id          = local.create_database_subnet ? azurerm_subnet.database[0].id : data.azurerm_subnet.database[0].id

  sku_name   = "B_Standard_B2ms"
  version    = "8.0.21"
  
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false

  storage {
    iops    = 360
    size_gb = 20
    auto_grow_enabled = true
  }

    lifecycle {
      ignore_changes = [
        zone
      ]
  }
}

resource "random_password" "db_password" {
  count             = local.create_database ? 1 : 0
  length            = 16
  special           = false
  min_lower         = 1
  min_upper         = 1
  min_numeric       = 1
}

resource "azurerm_key_vault_secret" "database_password" {
  count        = local.create_database ? 1 : 0
  depends_on   = [time_sleep.delay_create, azurerm_key_vault_access_policy.admin] # As policies are created in the same deployment add some delays to propagate
  name         = format("%s-password", azurerm_mysql_flexible_server.mysql[0].administrator_login)
  value        = random_password.db_password[0].result
  key_vault_id = azurerm_key_vault.azhop.id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

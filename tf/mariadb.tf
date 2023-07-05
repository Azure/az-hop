resource "azurerm_mariadb_server" "mariadb" {
  count               = local.create_database ? 1 : 0
  name                = local.mariadb_name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  administrator_login          = local.database_user
  administrator_login_password = random_password.mariadb_password[0].result

  sku_name   = "GP_Gen5_2"
  version    = "10.3"

  backup_retention_days             = 35
  geo_redundant_backup_enabled      = false
  public_network_access_enabled     = false
  # SSL enforce to be false when using Windows Remote Viz because Guacamole 1.4.0 with MariaDB doesn't support SSL. Need to upgrade to 1.5.0 
  ssl_enforcement_enabled           = local.enable_remote_winviz ? false : true
  auto_grow_enabled                 = true
  storage_mb                        = 5120
}

resource "azurerm_private_dns_zone" "mariadb_private_link" {
  count               = local.create_database ? 1 : 0
  name                = local.mariadb_private_dns_zone # "privatelink.mariadb.database.azure.com" # This name depends on the cloud env https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mariadb_dns_link" {
  count                 = local.create_database ? 1 : 0
  name                  = "az-hop-private"
  resource_group_name   = azurerm_private_dns_zone.mariadb_private_link[0].resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mariadb_private_link[0].name
  virtual_network_id    = local.create_vnet ? azurerm_virtual_network.azhop[0].id : data.azurerm_virtual_network.azhop[0].id
  registration_enabled  = false
}

resource azurerm_private_endpoint "mariadb"  {
  count               = local.create_database ? 1 : 0
  name                = "${local.mariadb_name}-pe"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  subnet_id           = local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.mariadb_private_link[0].id]
  }

  private_service_connection {
    name                              = "${local.mariadb_name}-private-connection"
    private_connection_resource_id    = azurerm_mariadb_server.mariadb[0].id
    is_manual_connection              = false
    subresource_names                 = [ "mariadbServer" ]
  }
}

resource "random_password" "mariadb_password" {
  count             = local.create_database ? 1 : 0
  length            = 16
  special           = false
  min_lower         = 1
  min_upper         = 1
  min_numeric       = 1
}

resource "azurerm_key_vault_secret" "mariadb_password" {
  count        = local.create_database ? 1 : 0
  depends_on   = [time_sleep.delay_create, azurerm_key_vault_access_policy.admin] # As policies are created in the same deployment add some delays to propagate
  name         = format("%s-password", azurerm_mariadb_server.mariadb[0].administrator_login)
  value        = random_password.mariadb_password[0].result
  key_vault_id = azurerm_key_vault.azhop.id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

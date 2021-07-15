resource "azurerm_netapp_account" "azhop" {
  name                = "hpcanf-${random_string.resource_postfix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_netapp_pool" "anfpool" {
  name                = "anfpool-${random_string.resource_postfix.result}"
  account_name        = azurerm_netapp_account.azhop.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_level       = local.homefs_service_level
  size_in_tb          = local.homefs_size_tb
}
resource "azurerm_netapp_volume" "home" {
#  lifecycle {
#    prevent_destroy = true
#  }

  name                = "anfhome"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_netapp_account.azhop.name
  pool_name           = azurerm_netapp_pool.anfpool.name
  volume_path         = "home-${random_string.resource_postfix.result}"
  service_level       = local.homefs_service_level
  subnet_id           = local.create_vnet ? azurerm_subnet.netapp[0].id : data.azurerm_subnet.netapp[0].id
  protocols           = ["NFSv3"]
  storage_quota_in_gb = local.homefs_size_tb * 1024

  export_policy_rule {
    rule_index        = 1 
    allowed_clients   = [ "0.0.0.0/0" ]
    unix_read_write   = true
    protocols_enabled = [ "NFSv3" ]
  }
}

resource "azurerm_netapp_account" "azhop" {
  name                = "hpcanf-${random_string.resource_postfix.result}"
  resource_group_name = azurerm_resource_group.rg[0].name
  location            = azurerm_resource_group.rg[0].location
  active_directory {
    username            = local.admin_username 
    password            = azurerm_windows_virtual_machine.ad.admin_password 
    smb_server_name     = "anf"
    dns_servers         = [azurerm_network_interface.ad-nic.private_ip_address]
    domain              = "hpc.azure"
  }
}
resource "azurerm_netapp_pool" "anfpool" {
  name                = "anfpool-${random_string.resource_postfix.result}"
  account_name        = azurerm_netapp_account.azhop.name
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
  service_level       = local.homefs_service_level
  size_in_tb          = local.homefs_size_tb
}
resource "azurerm_netapp_volume" "home" {
#  lifecycle {
#    prevent_destroy = true
#  }

  name                = "anfhome"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
  account_name        = azurerm_netapp_account.azhop.name
  pool_name           = azurerm_netapp_pool.anfpool.name
  volume_path         = "home-${random_string.resource_postfix.result}"
  service_level       = local.homefs_service_level
  subnet_id           = azurerm_subnet.netapp[0].id
  protocols           = [ "NFSv3", "CIFS" ]
  security_style      = "Unix"
  storage_quota_in_gb = local.homefs_size_tb * 1024

  export_policy_rule {
    rule_index        = 1 
    allowed_clients   = [ "0.0.0.0/0" ]
    unix_read_write   = true
    protocols_enabled = [ "NFSv3" ]
    root_access_enabled = true
  }
}

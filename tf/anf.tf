resource "azurerm_netapp_account" "deployhpc" {
  name                = "hpcanf-${random_string.random.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
resource "azurerm_netapp_pool" "anfpool" {
  name                = "anfpool-${random_string.random.result}"
  account_name        = azurerm_netapp_account.deployhpc.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_level       = "Standard"
  size_in_tb          = 4
}
resource "azurerm_netapp_volume" "home" {
  lifecycle {
    prevent_destroy = true
  }

  name                = "anfhome"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_netapp_account.deployhpc.name
  pool_name           = azurerm_netapp_pool.anfpool.name
  volume_path         = "home-${random_string.random.result}"
  service_level       = "Standard"
  subnet_id           = azurerm_subnet.netapp.id
  protocols           = ["NFSv3"]
  storage_quota_in_gb = 100

  export_policy_rule {
    rule_index        = 1 
    allowed_clients   = [ "0.0.0.0/0" ]
    unix_read_write   = true
    protocols_enabled = [ "NFSv3" ]
  }
}

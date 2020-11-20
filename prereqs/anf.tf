resource "azurerm_netapp_account" "deployhpc" {
  name                = "hpcanf"
  resource_group_name = azurerm_resource_group.deployhpc.name
  location            = azurerm_resource_group.deployhpc.location
}
resource "azurerm_netapp_pool" "anfpool" {
  name                = "anfpool"
  account_name        = azurerm_netapp_account.deployhpc.name
  location            = azurerm_resource_group.deployhpc.location
  resource_group_name = azurerm_resource_group.deployhpc.name
  service_level       = "Standard"
  size_in_tb          = 4
}
resource "azurerm_netapp_volume" "home" {
  lifecycle {
    prevent_destroy = true
  }

  name                = "anfhome"
  location            = azurerm_resource_group.deployhpc.location
  resource_group_name = azurerm_resource_group.deployhpc.name
  account_name        = azurerm_netapp_account.deployhpc.name
  pool_name           = azurerm_netapp_pool.anfpool.name
  volume_path         = "home20201120"
  service_level       = "Standard"
  subnet_id           = azurerm_subnet.netapp.id
  protocols           = ["NFSv3"]
  storage_quota_in_gb = 100
}

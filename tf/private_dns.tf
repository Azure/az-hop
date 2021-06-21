
resource "azurerm_private_dns_zone" "azhop_private_dns" {
  name                = "hpc.azure"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "azhop_dns_link" {
  name                  = "az-hop"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.azhop_private_dns.name
  virtual_network_id    = azurerm_virtual_network.azhop.id
  registration_enabled  = true
}

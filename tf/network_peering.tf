# Retrieve the peernetwork
# If count is 0 the variables for name and resource group are not set, so setting fake values, but as count is 0 this won't be executed
data "azurerm_virtual_network" "peernetwork" {
  count               = local.create_peering
  resource_group_name = local.create_peering == 1 ? local.peering_vnet_resource_group : "empty"
  name                = local.create_peering == 1 ? local.peering_vnet_name : "empty"
}

resource "azurerm_virtual_network_peering" "azhop-to-peer" {
  count                         = local.create_peering
  name                          = "azhop-to-peer"
  resource_group_name           = azurerm_resource_group.rg.name
  virtual_network_name          = azurerm_virtual_network.azhop[0].name
  remote_virtual_network_id     = data.azurerm_virtual_network.peernetwork[count.index].id
  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
}

resource "azurerm_virtual_network_peering" "peer-to-azhop" {
  count                         = local.create_peering
  name                          = "peer-to-azhop"
  resource_group_name           = data.azurerm_virtual_network.peernetwork[count.index].resource_group_name
  virtual_network_name          = data.azurerm_virtual_network.peernetwork[count.index].name
  remote_virtual_network_id     = azurerm_virtual_network.azhop[0].id
  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
}

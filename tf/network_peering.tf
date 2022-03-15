data "azurerm_virtual_network" "peernetwork" {
  count               = length(local.vnet_peering)
  resource_group_name = local.vnet_peering[count.index].vnet_resource_group
  name                = local.vnet_peering[count.index].vnet_name
}

resource "azurerm_virtual_network_peering" "azhop-to-peer" {
  count                         = length(local.vnet_peering)
  name                          = "azhop-to-${local.vnet_peering[count.index].vnet_name}"
  resource_group_name           = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  virtual_network_name          = azurerm_virtual_network.azhop[0].name
  remote_virtual_network_id     = data.azurerm_virtual_network.peernetwork[count.index].id
  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
}

resource "azurerm_virtual_network_peering" "peer-to-azhop" {
  count                         = length(local.vnet_peering)
  name                          = "${local.vnet_peering[count.index].vnet_name}-to-azhop"
  resource_group_name           = local.vnet_peering[count.index].vnet_resource_group
  virtual_network_name          = local.vnet_peering[count.index].vnet_name
  remote_virtual_network_id     = azurerm_virtual_network.azhop[0].id
  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
}
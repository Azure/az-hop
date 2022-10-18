data "azurerm_virtual_network" "peernetwork" {
  count               = length(local.vnet_peering)
  resource_group_name = local.vnet_peering[count.index].vnet_resource_group
  name                = local.vnet_peering[count.index].vnet_name
}

resource "azurerm_virtual_network_peering" "azhop-to-peer" {
  count                         = length(local.vnet_peering)
  name                          = "${local.vnet_peering[count.index].vnet_resource_group}-${local.vnet_peering[count.index].vnet_name}"
  resource_group_name           = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  virtual_network_name          = azurerm_virtual_network.azhop[0].name
  remote_virtual_network_id     = data.azurerm_virtual_network.peernetwork[count.index].id
  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
  use_remote_gateways           = try(local.vnet_peering[count.index].vnet_allow_gateway, true)
}

resource "azurerm_virtual_network_peering" "peer-to-azhop" {
  count                         = length(local.vnet_peering)
  name                          = local.create_rg ? "${azurerm_resource_group.rg[0].name}-${local.vnet_peering[count.index].vnet_name}" : "${data.azurerm_resource_group.rg[0].name}-${local.vnet_peering[count.index].vnet_name}"
  resource_group_name           = local.vnet_peering[count.index].vnet_resource_group
  virtual_network_name          = local.vnet_peering[count.index].vnet_name
  remote_virtual_network_id     = azurerm_virtual_network.azhop[0].id
  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
  allow_gateway_transit         = try(local.vnet_peering[count.index].vnet_allow_gateway, true)
}

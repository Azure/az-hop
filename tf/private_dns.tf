
resource "azurerm_private_dns_zone" "azhop_private_dns" {
  name                = "hpc.azure"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "azhop_dns_link" {
  name                  = "az-hop"
  resource_group_name   = azurerm_private_dns_zone.azhop_private_dns.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.azhop_private_dns.name
  virtual_network_id    = local.create_vnet ? azurerm_virtual_network.azhop[0].id : data.azurerm_virtual_network.azhop[0].id
  registration_enabled  = true
}

# resource "azurerm_private_dns_srv_record" "ldap_record" {
#   name                = "_ldap._tcp"
#   resource_group_name = azurerm_resource_group.rg.name
#   zone_name           = azurerm_private_dns_zone.azhop_private_dns.name
#   ttl                 = 3600

#   record {
#     priority = 1
#     weight   = 100
#     port     = 389
#     target   = azurerm_network_interface.ad-nic.private_ip_address
#   }

# }
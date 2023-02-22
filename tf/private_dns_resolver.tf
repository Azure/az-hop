resource "azurerm_private_dns_resolver" "dns_resolver" {
  count               = local.create_outbounddns_subnet ? 1 : 0
  name                = "dns-resolver-${random_string.resource_postfix.result}"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  virtual_network_id  = local.create_vnet ? azurerm_virtual_network.azhop[0].id : data.azurerm_virtual_network.azhop[0].id
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "resolver_outbound_endpoint" {
  count                   = local.create_outbounddns_subnet ? 1 : 0
  name                    = "dns-outbound-endpoint-${random_string.resource_postfix.result}"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns_resolver[0].id
  location                = azurerm_private_dns_resolver.dns_resolver[0].location
  subnet_id               = local.create_outbounddns_subnet ? azurerm_subnet.outbounddns[0].id : data.azurerm_subnet.outbounddns[0].id
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "forwarding_ruleset" {
  count                                      = local.create_dnsfw_rules ? 1 : 0
  name                                       = "dns-fw-ruleset-${random_string.resource_postfix.result}"
  resource_group_name                        = azurerm_private_dns_resolver.dns_resolver[0].resource_group_name
  location                                   = azurerm_private_dns_resolver.dns_resolver[0].location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.resolver_outbound_endpoint[0].id]
}

resource "azurerm_private_dns_resolver_virtual_network_link" "resolver_vnet_link" {
  count                     = local.create_dnsfw_rules ? 1 : 0
  name                      = "dsn-link-${random_string.resource_postfix.result}"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.forwarding_ruleset[0].id
  virtual_network_id        = local.create_vnet ? azurerm_virtual_network.azhop[0].id : data.azurerm_virtual_network.azhop[0].id
}


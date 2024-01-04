
resource "azurerm_nat_gateway" "natgateway" {
  count                     = local.create_nat_gateway ? 1 : 0
  name                      = local.nat_gateway_name
  location                  = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name       = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  sku_name                  = "Standard"
  idle_timeout_in_minutes   = 4
}

resource "azurerm_public_ip" "pip_natgateway" {
  count                     = local.create_nat_gateway ? 1 : 0
  name                      = "pip-${local.nat_gateway_name}"
  location                  = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name       = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  allocation_method         = "Static"
  sku                       = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "natgateway_pip_association" {
  count                = local.create_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.natgateway[0].id
  public_ip_address_id = azurerm_public_ip.pip_natgateway[0].id
}

resource "azurerm_subnet_nat_gateway_association" "frontend_natgateway_association" {
  count          = local.create_nat_gateway && local.create_frontend_subnet ? 1 : 0
  subnet_id      = data.azurerm_subnet.subnets["frontend"].id
  nat_gateway_id = azurerm_nat_gateway.natgateway[0].id
}

resource "azurerm_subnet_nat_gateway_association" "admin_natgateway_association" {
  count          = local.create_nat_gateway && local.create_admin_subnet ? 1 : 0
  subnet_id      = data.azurerm_subnet.subnets["admin"].id
  nat_gateway_id = azurerm_nat_gateway.natgateway[0].id
}

resource "azurerm_subnet_nat_gateway_association" "compute_natgateway_association" {
  count          = local.create_nat_gateway && local.create_compute_subnet ? 1 : 0
  subnet_id      = data.azurerm_subnet.subnets["compute"].id
  nat_gateway_id = azurerm_nat_gateway.natgateway[0].id
}

resource "azurerm_subnet_nat_gateway_association" "ad_natgateway_association" {
  count          = local.create_nat_gateway && local.create_ad_subnet ? 1 : 0
  subnet_id      = data.azurerm_subnet.subnets["ad"].id
  nat_gateway_id = azurerm_nat_gateway.natgateway[0].id
}

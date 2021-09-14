# Main VNET
data "azurerm_virtual_network" "azhop" {
  count                = local.create_vnet ? 0 : 1
  name                 = try(split("/", local.vnet_id)[8], "foo")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
}

resource "azurerm_virtual_network" "azhop" {
  count               = local.create_vnet ? 1 : 0
  name                = try(local.configuration_yml["network"]["vnet"]["name"], "hpcvnet")
  resource_group_name = azurerm_resource_group.rg[0].name
  location            = azurerm_resource_group.rg[0].location
  address_space       = [try(local.configuration_yml["network"]["vnet"]["address_space"], "10.0.0.0/16")]
}
# Resource group of the existing vnet
data "azurerm_resource_group" "rg_vnet" {
  count    = local.create_vnet ? 0 : 1
  name     = try(split("/", local.vnet_id)[4], "foo")
}

# Frontend Subnet
data "azurerm_subnet" "frontend" {
  count                = local.create_vnet ? 0 : 1
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["frontend"]["name"], "frontend")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "frontend" {
  count                = local.create_vnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["frontend"]["name"], "frontend")
  virtual_network_name = azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["frontend"]["address_prefixes"], "10.0.0.0/24")]
}

# admin subnet
data "azurerm_subnet" "admin" {
  count                = local.create_vnet ? 0 : 1
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["admin"]["name"], "admin")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "admin" {
  count                = local.create_vnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["admin"]["name"], "admin")
  virtual_network_name = azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["admin"]["address_prefixes"], "10.0.1.0/24")]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# netapp subnet
data "azurerm_subnet" "netapp" {
  count                = local.create_vnet ? 0 : 1
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["netapp"]["name"], "netapp")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "netapp" {
  count                = local.create_vnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["netapp"]["name"], "netapp")
  virtual_network_name = azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["netapp"]["address_prefixes"], "10.0.2.0/24")]
  delegation {
    name = "netapp"

    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ad subnet
data "azurerm_subnet" "ad" {
  count                = local.create_vnet ? 0 : 1
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["ad"]["name"], "ad")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "ad" {
  count                = local.create_vnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["ad"]["name"], "ad")
  virtual_network_name = azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["ad"]["address_prefixes"], "10.0.3.0/28")]
}

# bastion subnet
data "azurerm_subnet" "bastion" {
  count                = local.create_vnet ? 0 : 1
  name                 = "AzureBastionSubnet"
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "bastion" {
  count                = local.create_vnet ? 1 : 0
  name                 = "AzureBastionSubnet"
  virtual_network_name = azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["bastion"]["address_prefixes"], "10.0.4.0/27")]
}

# compute subnet
data "azurerm_subnet" "compute" {
  count                = local.create_vnet ? 0 : 1
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["compute"]["name"], "compute")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "compute" {
  count                = local.create_vnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["compute"]["name"], "compute")
  virtual_network_name = azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["compute"]["address_prefixes"], "10.0.16.0/20")]
  service_endpoints    = ["Microsoft.Storage"]
}


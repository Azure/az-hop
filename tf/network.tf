# Main VNET
data "azurerm_virtual_network" "azhop" {
  count                = local.create_vnet ? 0 : 1
  name                 = try(split("/", local.vnet_id)[8], "foo")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
}

resource "azurerm_virtual_network" "azhop" {
  count               = local.create_vnet ? 1 : 0
  name                = try(local.configuration_yml["network"]["vnet"]["name"], "hpcvnet")
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  address_space       = [try(local.configuration_yml["network"]["vnet"]["address_space"], "10.0.0.0/23")]
}

#set VNet DNS servers if using the customers AD and hub
# resource "azurerm_virtual_network_dns_servers" "customer_dns" {
#   count              = local.create_ad ? 0 : 1
#   virtual_network_id = azurerm_virtual_network.azhop[0].id
#   dns_servers        = local.private_dns_servers
#}

# Resource group of the existing vnet
data "azurerm_resource_group" "rg_vnet" {
  count    = local.create_vnet ? 0 : 1
  name     = try(split("/", local.vnet_id)[4], "foo")
}

# Frontend Subnet
data "azurerm_subnet" "frontend" {
  count                = local.create_frontend_subnet ? 0 : 1
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["frontend"]["name"], "frontend")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "frontend" {
  count                = local.create_frontend_subnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["frontend"]["name"], "frontend")
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[count.index].name : data.azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = local.create_vnet ? azurerm_virtual_network.azhop[count.index].resource_group_name : data.azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["frontend"]["address_prefixes"], "10.0.0.0/29")]
  service_endpoints    = local.create_nfsfiles ? ["Microsoft.Storage"] : []
}

# admin subnet
data "azurerm_subnet" "admin" {
  count                = local.create_admin_subnet ? 0 : 1
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["admin"]["name"], "admin")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "admin" {
  count                = local.create_admin_subnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["admin"]["name"], "admin")
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[count.index].name : data.azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = local.create_vnet ? azurerm_virtual_network.azhop[count.index].resource_group_name : data.azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["admin"]["address_prefixes"], "10.0.0.16/28")]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# netapp subnet
data "azurerm_subnet" "netapp" {
  count                = local.create_netapp_subnet ? 0 : 1
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["netapp"]["name"], "netapp")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "netapp" {
  count                = local.create_netapp_subnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["netapp"]["name"], "netapp")
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[count.index].name : data.azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = local.create_vnet ? azurerm_virtual_network.azhop[count.index].resource_group_name : data.azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["netapp"]["address_prefixes"], "10.0.0.32/28")]
  delegation {
    name = "netapp"

    service_delegation {
      name    = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# database subnet
data "azurerm_subnet" "database" {
  count                = local.create_database_subnet ? 0 : (local.no_database_subnet ? 0 : 1)
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["database"]["name"], "database")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "database" {
  count                = local.create_database_subnet ? (local.no_database_subnet ? 0 : 1) : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["database"]["name"], "database")
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[count.index].name : data.azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = local.create_vnet ? azurerm_virtual_network.azhop[count.index].resource_group_name : data.azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["database"]["address_prefixes"], "10.0.0.224/28")]
  delegation {
    name = "database"

    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ad subnet
data "azurerm_subnet" "ad" {
  count                = local.create_ad_subnet ? 0 : (local.create_ad ? 1 : 0)
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["ad"]["name"], "ad")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "ad" {
  count                = local.create_ad_subnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["ad"]["name"], "ad")
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[count.index].name : data.azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = local.create_vnet ? azurerm_virtual_network.azhop[count.index].resource_group_name : data.azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["ad"]["address_prefixes"], "10.0.0.0/29")]
}

# bastion subnet
data "azurerm_subnet" "bastion" {
  count                = local.create_bastion_subnet ? 0 : (local.no_bastion_subnet ? 0 : 1)
  name                 = "AzureBastionSubnet"
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "bastion" {
  count                = local.create_bastion_subnet ? (local.no_bastion_subnet ? 0 : 1) : 0
  name                 = "AzureBastionSubnet"
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[count.index].name : data.azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = local.create_vnet ? azurerm_virtual_network.azhop[count.index].resource_group_name : data.azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.bastion_subnet["address_prefixes"], "10.0.0.64/26")]
}

# Gateway subnet
data "azurerm_subnet" "gateway" {
  count                = local.create_gateway_subnet ? 0 : (local.no_gateway_subnet ? 0 : 1)
  name                 = "GatewaySubnet"
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "gateway" {
  count                = local.create_gateway_subnet ? (local.no_gateway_subnet ? 0 : 1) : 0
  name                 = "GatewaySubnet"
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[count.index].name : data.azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = local.create_vnet ? azurerm_virtual_network.azhop[count.index].resource_group_name : data.azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.gateway_subnet["address_prefixes"], "10.0.0.128/27")]
}

# compute subnet
data "azurerm_subnet" "compute" {
  count                = local.create_compute_subnet ? 0 : 1
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["compute"]["name"], "compute")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "compute" {
  count                = local.create_compute_subnet ? 1 : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["compute"]["name"], "compute")
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[count.index].name : data.azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = local.create_vnet ? azurerm_virtual_network.azhop[count.index].resource_group_name : data.azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["compute"]["address_prefixes"], "10.0.1.0/24")]
  service_endpoints    = ["Microsoft.Storage"]
}

# outbounddns subnet - if using existing AD then a resolver won't be created as part of the deployment
data "azurerm_subnet" "outbounddns" {
  count                = local.create_outbounddns_subnet ? 0 : (local.create_ad ? (local.no_outbounddns_subnet ? 0 : 1) : 0)
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["outbounddns"]["name"], "outbounddns")
  resource_group_name  = try(split("/", local.vnet_id)[4], "foo")
  virtual_network_name = try(split("/", local.vnet_id)[8], "foo")
}

resource "azurerm_subnet" "outbounddns" {
  count                = local.create_outbounddns_subnet ? (local.no_outbounddns_subnet ? 0 : 1) : 0
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"]["outbounddns"]["name"], "outbounddns")
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[count.index].name : data.azurerm_virtual_network.azhop[count.index].name
  resource_group_name  = local.create_vnet ? azurerm_virtual_network.azhop[count.index].resource_group_name : data.azurerm_virtual_network.azhop[count.index].resource_group_name
  address_prefixes     = [try(local.configuration_yml["network"]["vnet"]["subnets"]["outbounddns"]["address_prefixes"], "10.0.0.48/28")]
  delegation {
    name = "Microsoft.Network.dnsResolvers"

    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


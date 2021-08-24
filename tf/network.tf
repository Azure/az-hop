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
# resource "azurerm_subnet" "bastion" {
#  name                 = "AzureBastionSubnet"
#  virtual_network_name = azurerm_virtual_network.azhop.name
#  resource_group_name  = azurerm_resource_group.rg.name
#  address_prefixes     = ["10.0.3.0/24"]
#}

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

# Network security group for the FrontEnd subnet
resource "azurerm_network_security_group" "frontend" {
  count                = local.create_vnet ? 1 : 0
  name                = "frontendnsg"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  security_rule {
        name                       = "ssh-in-allow-22"
        priority                   = "103"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
        name                       = "https-in-allow-443"
        priority                   = "104"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
        name                       = "https-in-allow-80"
        priority                   = "105"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_subnet_network_security_group_association" "frontend" {
  count                     = local.create_vnet ? 1 : 0
  subnet_id                 = azurerm_subnet.frontend[count.index].id
  network_security_group_id = azurerm_network_security_group.frontend[count.index].id
}
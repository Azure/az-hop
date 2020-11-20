resource "azurerm_virtual_network" "deployhpc" {
  name                = "hpcvnet"
  resource_group_name = azurerm_resource_group.deployhpc.name
  location            = azurerm_resource_group.deployhpc.location
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  virtual_network_name = azurerm_virtual_network.deployhpc.name
  resource_group_name  = azurerm_resource_group.deployhpc.name
  address_prefixes     = ["10.0.0.0/24"]
}
resource "azurerm_subnet" "admin" {
  name                 = "admin"
  virtual_network_name = azurerm_virtual_network.deployhpc.name
  resource_group_name  = azurerm_resource_group.deployhpc.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "netapp" {
  name                 = "netapp"
  virtual_network_name = azurerm_virtual_network.deployhpc.name
  resource_group_name  = azurerm_resource_group.deployhpc.name
  address_prefixes     = ["10.0.2.0/24"]
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
#  virtual_network_name = azurerm_virtual_network.deployhpc.name
#  resource_group_name  = azurerm_resource_group.deployhpc.name
#  address_prefixes     = ["10.0.3.0/24"]
#}
resource "azurerm_subnet" "compute" {
  name                 = "compute"
  virtual_network_name = azurerm_virtual_network.deployhpc.name
  resource_group_name  = azurerm_resource_group.deployhpc.name
  address_prefixes     = ["10.0.16.0/20"]
}

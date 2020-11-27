resource "azurerm_virtual_network" "deployhpc" {
  name                = "hpcvnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  virtual_network_name = azurerm_virtual_network.deployhpc.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.0.0/24"]
}
resource "azurerm_subnet" "admin" {
  name                 = "admin"
  virtual_network_name = azurerm_virtual_network.deployhpc.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "netapp" {
  name                 = "netapp"
  virtual_network_name = azurerm_virtual_network.deployhpc.name
  resource_group_name  = azurerm_resource_group.rg.name
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
#  resource_group_name  = azurerm_resource_group.rg.name
#  address_prefixes     = ["10.0.3.0/24"]
#}
resource "azurerm_subnet" "compute" {
  name                 = "compute"
  virtual_network_name = azurerm_virtual_network.deployhpc.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.16.0/20"]
}

# Network security group for the FrontEnd subnet
resource "azurerm_network_security_group" "frontend" {
  name                = "frontendnsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

}

resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}
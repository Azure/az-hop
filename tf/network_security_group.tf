# Application security groups
resource "azurerm_application_security_group" "asg" {
  for_each = local.create_vnet ? local.asgs : local.empty_map
  name                = each.key
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
}

data "azurerm_application_security_group" "asg" {
  for_each = local.create_vnet ? local.empty_map : local.asgs
  name                = each.key
  resource_group_name = local.create_vnet ? azurerm_resource_group.rg[0].name : data.azurerm_virtual_network.azhop[0].resource_group_name
}

# Network security group for the FrontEnd subnet
resource "azurerm_network_security_group" "frontend" {
  count                = local.create_vnet ? 1 : 0
  name                = "nsg-${local.create_vnet ? azurerm_subnet.frontend[0].name : data.azurerm_subnet.frontend[0].name}"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location

  #
  #         INBOUND
  #
  security_rule {
        name                       = "AllowSshIn"
        priority                   = "100"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Ssh"]
        source_address_prefix      = "*"
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-jumpbox"].id]
  }

  security_rule {
        name                       = "AllowWebUsers"
        priority                   = "110"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Web"]
        source_address_prefix      = "*"
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ondemand"].id]
  }

  security_rule {
        name                       = "AllowAdServerInTcp"
        priority                   = "120"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad-client"].id]
  }

  security_rule {
        name                       = "AllowAdServerInUdp"
        priority                   = "130"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad-client"].id]
  }

  security_rule {
        name                       = "AllowChronyIn"
        priority                   = "140"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Chrony"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-chrony"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ondemand"].id]
  }

  security_rule {
        name                       = "AllowChronyComputeIn"
        priority                   = "150"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Chrony"]
        source_address_prefixes = azurerm_subnet.netapp[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ondemand"].id]
  }

  security_rule {
        name                       = "AllowSshInFromJumpbox"
        priority                   = "160"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Ssh"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-jumpbox"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ssh"].id]
  }

  security_rule {
        name                       = "AllowSshInCompute"
        priority                   = "170"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Ssh"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ssh"].id]
  }

  security_rule {
        name                       = "AllowNoVncComputeIn"
        priority                   = "180"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["NoVnc"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ondemand"].id]
  }

  security_rule {
        name                       = "AllowPbsComputeIn"
        priority                   = "190"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ondemand"].id]
  }

  security_rule {
        name                       = "DenyVnetInbound"
        priority                   = "3100"
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
  }

  #
  #         OUTBOUND
  #
  security_rule {
        name                       = "AllowAdServerOutTcp"
        priority                   = "100"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerOutUdp"
        priority                   = "110"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowPbsOut"
        priority                   = "120"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-pbs-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-pbs"].id]
  }

  security_rule {
        name                       = "AllowLustreOut"
        priority                   = "130"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Lustre"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-lustre-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-lustre"].id]
  }

  security_rule {
        name                       = "AllowNFSOut"
        priority                   = "140"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Nfs"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-nfs-client"].id]
        destination_address_prefixes = azurerm_subnet.netapp[0].address_prefixes
  }

  security_rule {
        name                       = "AllowTelegrafOut"
        priority                   = "150"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Telegraf"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-telegraf"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-grafana"].id]
  }

  security_rule {
        name                       = "AllowGrafanaOut"
        priority                   = "160"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Grafana"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ondemand"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-grafana"].id]
  }

  security_rule {
        name                       = "AllowCycleOut"
        priority                   = "170"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Web"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ondemand"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-cyclecloud"].id]
  }

  security_rule {
        name                       = "AllowRobinhoodOut"
        priority                   = "180"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Web"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ondemand"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-robinhood"].id]
  }

  security_rule {
        name                       = "AllowDnsOut"
        priority                   = "190"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Dns"]
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
        name                       = "AllowRdpOut"
        priority                   = "200"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Rdp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-jumpbox"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-rdp"].id]
  }

  security_rule {
        name                       = "AllowSshOut"
        priority                   = "210"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Ssh"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-jumpbox"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ssh"].id]
  }

  security_rule {
        name                       = "AllowNoVncComputeOut"
        priority                   = "220"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["NoVnc"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ondemand"].id]
        destination_address_prefixes = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowSshComputeOut"
        priority                   = "230"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Ssh"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ssh"].id]
        destination_address_prefixes = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowSocksOut"
        priority                   = "240"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Socks"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-jumpbox"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  # security_rule {
  #       name                       = "AllowOnDemandToAd"
  #       priority                   = "250"
  #       direction                  = "Outbound"
  #       access                     = "Allow"
  #       protocol                   = "*"
  #       source_port_range          = "*"
  #       destination_port_range     = "*"
  #       source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ondemand"].id]
  #       destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  # }

  security_rule {
        name                       = "AllowInternetOutBound"
        priority                   = "3000"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "Internet"
  }

  security_rule {
        name                       = "DenyVnetOutBound"
        priority                   = "3100"
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
  }

}

resource "azurerm_subnet_network_security_group_association" "frontend" {
  count                     = local.create_vnet ? 1 : 0
  subnet_id                 = azurerm_subnet.frontend[count.index].id
  network_security_group_id = azurerm_network_security_group.frontend[count.index].id
}

# Network security group for the Admin subnet
resource "azurerm_network_security_group" "admin" {
  count                = local.create_vnet ? 1 : 0
  name                = "nsg-${local.create_vnet ? azurerm_subnet.admin[0].name : data.azurerm_subnet.admin[0].name}"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location

  #
  #         INBOUND
  #
  security_rule {
        name                       = "AllowSshIn"
        priority                   = "100"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Ssh"]
        source_application_security_group_ids  = [azurerm_application_security_group.asg["asg-jumpbox"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ssh"].id]
  }

  security_rule {
        name                       = "AllowRdpIn"
        priority                   = "110"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Rdp"]
        source_application_security_group_ids  = [azurerm_application_security_group.asg["asg-jumpbox"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerInTcp"
        priority                   = "120"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerInComputeTcp"
        priority                   = "130"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerInNetAppTcp"
        priority                   = "140"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_address_prefixes    = azurerm_subnet.netapp[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerInUdp"
        priority                   = "150"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerInComputeUdp"
        priority                   = "160"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerInNetAppUdp"
        priority                   = "170"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_address_prefixes    = azurerm_subnet.netapp[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowTelegrafIn"
        priority                   = "180"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Telegraf"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-telegraf"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-grafana"].id]
  }

  security_rule {
        name                       = "AllowTelegrafComputeIn"
        priority                   = "190"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Telegraf"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-grafana"].id]
  }

  security_rule {
        name                       = "AllowGrafanaIn"
        priority                   = "200"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Grafana"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ondemand"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-grafana"].id]
  }

  security_rule {
        name                       = "AllowCycleWebIn"
        priority                   = "210"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Web"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ondemand"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-cyclecloud"].id]
  }

  security_rule {
        name                       = "AllowCycleClientIn"
        priority                   = "220"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["CycleCloud"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-cyclecloud-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-cyclecloud"].id]
  }

  security_rule {
        name                       = "AllowCycleClientComputeIn"
        priority                   = "230"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["CycleCloud"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-cyclecloud"].id]
  }

  security_rule {
        name                       = "AllowPbsIn"
        priority                   = "240"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-pbs-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-pbs"].id]
  }

  security_rule {
        name                       = "AllowPbsComputeIn"
        priority                   = "250"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-pbs"].id]
  }

  security_rule {
        name                       = "AllowLustreIn"
        priority                   = "260"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Lustre"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-lustre-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-lustre"].id]
  }

  security_rule {
        name                       = "AllowLustreComputeIn"
        priority                   = "270"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Lustre"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-lustre"].id]
  }

  security_rule {
        name                       = "AllowRobinhoodIn"
        priority                   = "280"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Web"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ondemand"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-robinhood"].id]
  }

  security_rule {
        name                       = "AllowSocksIn"
        priority                   = "290"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Socks"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-jumpbox"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  # security_rule {
  #       name                       = "AllowOnDemandToAd"
  #       priority                   = "300"
  #       direction                  = "Inbound"
  #       access                     = "Allow"
  #       protocol                   = "*"
  #       source_port_range          = "*"
  #       destination_port_range     = "*"
  #       source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ondemand"].id]
  #       destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  # }

  security_rule {
        name                       = "DenyVnetInbound"
        priority                   = "3100"
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
  }

  #
  #         OUTBOUND
  #
  security_rule {
        name                       = "AllowAdServerOutTcp"
        priority                   = "100"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad-client"].id]
  }

  security_rule {
        name                       = "AllowAdClientOutTcp"
        priority                   = "110"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerComputeOutTcp"
        priority                   = "120"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad"].id]
        destination_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowAdServerOutUdp"
        priority                   = "130"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad-client"].id]
  }

  security_rule {
        name                       = "AllowAdClientOutUdp"
        priority                   = "140"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerComputeOutUdp"
        priority                   = "150"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad"].id]
        destination_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowDnsOut"
        priority                   = "160"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Dns"]
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
        name                       = "AllowCycleServerOut"
        priority                   = "170"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["CycleCloud"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-cyclecloud"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-cyclecloud-client"].id]
  }

  security_rule {
        name                       = "AllowCycleClientOut"
        priority                   = "180"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["CycleCloud"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-cyclecloud-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-cyclecloud"].id]
  }

  security_rule {
        name                       = "AllowCycleClientComputeOut"
        priority                   = "190"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["CycleCloud"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-cyclecloud"].id]
        destination_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowPbsOut"
        priority                   = "200"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-pbs"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-pbs-client"].id]
  }

  security_rule {
        name                       = "AllowPbsClientOut"
        priority                   = "210"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-pbs-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-pbs"].id]
  }

  security_rule {
        name                       = "AllowPbsComputeOut"
        priority                   = "220"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-pbs"].id]
        destination_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowLustreOut"
        priority                   = "230"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Lustre"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-lustre"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-lustre-client"].id]
  }

  security_rule {
        name                       = "AllowLustreClientOut"
        priority                   = "240"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Lustre"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-lustre-client"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-lustre"].id]
  }

  security_rule {
        name                       = "AllowLustreComputeOut"
        priority                   = "250"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Lustre"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-lustre"].id]
        destination_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowNFSOut"
        priority                   = "260"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Nfs"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-nfs-client"].id]
        destination_address_prefixes = azurerm_subnet.netapp[0].address_prefixes
  }

  security_rule {
        name                       = "AllowChronyOut"
        priority                   = "270"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Chrony"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-chrony"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ondemand"].id]
  }

  security_rule {
        name                       = "AllowTelegrafOut"
        priority                   = "280"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Telegraf"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-telegraf"].id]
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-grafana"].id]
  }

  security_rule {
        name                       = "AllowInternetOutBound"
        priority                   = "3000"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "Internet"
  }

  security_rule {
        name                       = "DenyVnetOutBound"
        priority                   = "3100"
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_subnet_network_security_group_association" "admin" {
  count                     = local.create_vnet ? 1 : 0
  subnet_id                 = azurerm_subnet.admin[count.index].id
  network_security_group_id = azurerm_network_security_group.admin[count.index].id
}

# Network security group for the Compute subnet
resource "azurerm_network_security_group" "compute" {
  count                = local.create_vnet ? 1 : 0
  name                = "nsg-${local.create_vnet ? azurerm_subnet.compute[0].name : data.azurerm_subnet.compute[0].name}"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location

  #
  #         INBOUND
  #
  security_rule {
        name                       = "AllowSshIn"
        priority                   = "100"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Ssh"]
        source_application_security_group_ids  = [azurerm_application_security_group.asg["asg-ondemand"].id]
        destination_address_prefixes = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowAdServerInTcp"
        priority                   = "110"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad"].id]
        destination_address_prefixes = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowAdServerInUdp"
        priority                   = "120"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-ad"].id]
        destination_address_prefixes = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowPbsIn"
        priority                   = "130"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_application_security_group_ids      = [azurerm_application_security_group.asg["asg-pbs"].id]
        destination_address_prefixes = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowNoVncIn"
        priority                   = "140"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["NoVnc"]
        source_application_security_group_ids  = [azurerm_application_security_group.asg["asg-ondemand"].id]
        destination_address_prefixes = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "DenyVnetInbound"
        priority                   = "3100"
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
  }

  #
  #         OUTBOUND
  #
  security_rule {
        name                       = "AllowAdServerOutTcp"
        priority                   = "100"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerTcp"]
        source_address_prefixes = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowAdServerOutUdp"
        priority                   = "110"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["DomainControlerUdp"]
        source_address_prefixes = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ad"].id]
  }

  security_rule {
        name                       = "AllowDnsOut"
        priority                   = "120"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Dns"]
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
        name                       = "AllowCycleClientOut"
        priority                   = "130"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["CycleCloud"]
        source_address_prefixes = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-cyclecloud"].id]
  }

  security_rule {
        name                       = "AllowPbsOut"
        priority                   = "140"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_address_prefixes = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-pbs"].id]
  }

  security_rule {
        name                       = "AllowLustreOut"
        priority                   = "150"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Lustre"]
        source_address_prefixes = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-lustre"].id]
  }

  security_rule {
        name                       = "AllowNFSOut"
        priority                   = "160"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Nfs"]
        source_address_prefixes = azurerm_subnet.compute[0].address_prefixes
        destination_address_prefixes = azurerm_subnet.netapp[0].address_prefixes
  }

  security_rule {
        name                       = "AllowChronyOut"
        priority                   = "170"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Chrony"]
        source_address_prefixes = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ondemand"].id]
  }

  security_rule {
        name                       = "AllowNoVncOut"
        priority                   = "180"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["NoVnc"]
        source_address_prefixes = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ondemand"].id]
  }

  security_rule {
        name                       = "AllowSshOutCompute"
        priority                   = "190"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Ssh"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ssh"].id]
  }

  security_rule {
        name                       = "AllowSshBetweenCompute"
        priority                   = "200"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "tcp"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Ssh"]
        source_address_prefixes    = azurerm_subnet.compute[0].address_prefixes
        destination_address_prefixes = azurerm_subnet.compute[0].address_prefixes
  }

  security_rule {
        name                       = "AllowPbsOnDemandOut"
        priority                   = "210"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = local.nsg_destination_ports["Pbs"]
        source_address_prefixes = azurerm_subnet.compute[0].address_prefixes
        destination_application_security_group_ids = [azurerm_application_security_group.asg["asg-ondemand"].id]
  }

  security_rule {
        name                       = "AllowInternetOutBound"
        priority                   = "3000"
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "Internet"
  }

  security_rule {
        name                       = "DenyVnetOutBound"
        priority                   = "3100"
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
  }
}


resource "azurerm_subnet_network_security_group_association" "compute" {
  count                     = local.create_vnet ? 1 : 0
  subnet_id                 = azurerm_subnet.compute[count.index].id
  network_security_group_id = azurerm_network_security_group.compute[count.index].id
}

# NSG cannot be applied on a delegated subnet for Azure Netapp files https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-delegate-subnet
# # Network security group for the netapp subnet
# resource "azurerm_network_security_group" "netapp" {
#   count                = local.create_vnet ? 1 : 0
#   name                = "nsg-${local.create_vnet ? azurerm_subnet.netapp[0].name : data.azurerm_subnet.netapp[0].name}"
#   location            = azurerm_resource_group.rg[0].location
#   resource_group_name = azurerm_resource_group.rg[0].name

# }

# resource "azurerm_subnet_network_security_group_association" "netapp" {
#   count                     = local.create_vnet ? 1 : 0
#   subnet_id                 = azurerm_subnet.netapp[count.index].id
#   network_security_group_id = azurerm_network_security_group.netapp[count.index].id
# }

resource "time_sleep" "wait_forsubnets" {
  depends_on   = [azurerm_subnet.ad, 
                  azurerm_subnet.frontend, 
                  azurerm_subnet.admin, 
                  azurerm_subnet.netapp, 
                  azurerm_subnet.compute, 
                  azurerm_subnet.bastion, 
                  azurerm_subnet.gateway] 
  create_duration = "20s"
}

# Application security groups
resource "azurerm_application_security_group" "asg" {
  for_each = local.create_nsg ? local.asgs : local.empty_map
  name                = each.key
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
}

data "azurerm_application_security_group" "asg" {
  for_each = local.create_nsg ? local.empty_map : local.asgs
  name                = each.key
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
}

# Read subnets data so we can dynamically retrieve all CIDR for the NSG rules
data "azurerm_subnet" "subnets" {
  depends_on   = [time_sleep.wait_forsubnets] 
  for_each = local.subnets
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"][each.key]["name"], each.value)
  resource_group_name  = local.create_vnet ? (local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name) : data.azurerm_virtual_network.azhop[0].resource_group_name
  virtual_network_name = local.create_vnet ? azurerm_virtual_network.azhop[0].name : data.azurerm_virtual_network.azhop[0].name
}

# Network security group for all subnets, always create this resource so we can add dynamic content
resource "azurerm_network_security_group" "common" {
  name                = "nsg-common"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location

  dynamic "security_rule" {
    for_each = local.create_nsg ? local.nsg_rules : local.empty_map
    content {
      name                       = security_rule.key
      priority                   = security_rule.value[0]
      direction                  = security_rule.value[1]
      access                     = security_rule.value[2]
      protocol                   = security_rule.value[3]
      source_port_range          = "*"
      destination_port_ranges    = local.nsg_destination_ports[security_rule.value[4]]

      source_address_prefix                 = try(split("/", security_rule.value[5])[0] == "tag" ? split("/", security_rule.value[5])[1] : null, null)
      source_application_security_group_ids = split("/", security_rule.value[5])[0] == "asg" ? [azurerm_application_security_group.asg[split("/", security_rule.value[5])[1]].id] : []
      source_address_prefixes               = try(split("/", security_rule.value[5])[0] == "subnet" ? data.azurerm_subnet.subnets[split("/", security_rule.value[5])[1]].address_prefixes : null, null)

      destination_address_prefix                 = try(split("/", security_rule.value[6])[0] == "tag" ? split("/", security_rule.value[6])[1] : null, null)
      destination_application_security_group_ids = split("/", security_rule.value[6])[0] == "asg" ? [azurerm_application_security_group.asg[split("/", security_rule.value[6])[1]].id] : []
      destination_address_prefixes               = try(split("/", security_rule.value[6])[0] == "subnet" ? data.azurerm_subnet.subnets[split("/", security_rule.value[6])[1]].address_prefixes : null, null)
    }
  }
}

# NSG cannot be applied on a delegated subnet for Azure Netapp files https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-delegate-subnet, nor on Bastion

resource "azurerm_subnet_network_security_group_association" "frontend" {
  count                     = local.create_nsg ? 1 : 0
  subnet_id                 = azurerm_subnet.frontend[count.index].id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_subnet_network_security_group_association" "ad" {
  count                     = local.create_nsg ? 1 : 0
  subnet_id                 = azurerm_subnet.ad[count.index].id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_subnet_network_security_group_association" "compute" {
  count                     = local.create_nsg ? 1 : 0
  subnet_id                 = azurerm_subnet.compute[count.index].id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_subnet_network_security_group_association" "admin" {
  count                     = local.create_nsg ? 1 : 0
  subnet_id                 = azurerm_subnet.admin[count.index].id
  network_security_group_id = azurerm_network_security_group.common.id
}

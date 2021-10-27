# Main VNET
locals {
  vnet_rg   = local.create_vnet ? (local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name) : try(split("/", local.vnet_id)[4], "foo")
  vnet_name = local.create_vnet ? try(local.configuration_yml["network"]["vnet"]["name"], "hpcvnet") : try(split("/", local.vnet_id)[8], "foo")
}

data "azurerm_virtual_network" "azhop" {
  name                 = local.vnet_name
  resource_group_name  = local.vnet_rg
}

# Read subnets data so we can dynamically retrieve all CIDR for the NSG rules
data "azurerm_subnet" "subnets" {
  depends_on   = [azurerm_subnet.ad, 
                  azurerm_subnet.frontend, 
                  azurerm_subnet.admin, 
                  azurerm_subnet.netapp, 
                  azurerm_subnet.compute, 
                  azurerm_subnet.bastion, 
                  azurerm_subnet.gateway] 
  for_each = local.subnets
  name                 = try(local.configuration_yml["network"]["vnet"]["subnets"][each.key]["name"], each.value)
  resource_group_name  = local.vnet_rg
  virtual_network_name = local.vnet_name
}

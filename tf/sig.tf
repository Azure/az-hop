resource "azurerm_shared_image_gallery" "sig" {
  count               = local.create_sig ? 1 : 0
  name                = local.sig_name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  description         = "Shared images for AZHOP"
}


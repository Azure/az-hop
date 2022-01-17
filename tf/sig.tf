resource "azurerm_shared_image_gallery" "sig" {
  name                = "azhop_${random_string.resource_postfix.result}"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  description         = "Shared images for AZHOP"
}

# TODO : create a loop with all the image definitions defined in the config.yml file
# resource "azurerm_shared_image" "example" {
#   name                = "my-image"
#   gallery_name        = azurerm_shared_image_gallery.sig.name
#   resource_group_name = azurerm_resource_group.sig.name
#   location            = azurerm_resource_group.sig.location
#   os_type             = "Linux"

#   identifier {
#     publisher = "PublisherName"
#     offer     = "OfferName"
#     sku       = "ExampleSku"
#   }
# }

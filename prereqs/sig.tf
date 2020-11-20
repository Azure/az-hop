resource "azurerm_shared_image_gallery" "deployhpc" {
  name                = "hpcready"
  resource_group_name = azurerm_resource_group.deployhpc.name
  location            = azurerm_resource_group.deployhpc.location
  description         = "Shared images for HPC"
}

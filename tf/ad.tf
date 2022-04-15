resource "azurerm_network_interface" "ad-nic" {
  name                = "ad-nic"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_ad_subnet ? azurerm_subnet.ad[0].id : data.azurerm_subnet.ad[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "ad" {
  name                = "ad"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  size                = try(local.configuration_yml["ad"].vm_size, "Standard_D2s_v3")
  admin_username      = local.admin_username
  admin_password      = random_password.password.result
  license_type        = try(local.configuration_yml["ad"].hybrid_benefit, false) ? "Windows_Server" : "None"

  network_interface_ids = [
    azurerm_network_interface.ad-nic.id,
  ]

  winrm_listener {
    protocol = "Http"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  dynamic "source_image_reference" {
    for_each = local.use_windows_image_id ? [] : [1]
    content {
      publisher = local.windows_base_image_reference.publisher
      offer     = local.windows_base_image_reference.offer
      sku       = local.windows_base_image_reference.sku
      version   = local.windows_base_image_reference.version
    }
  }

  source_image_id = local.windows_image_id

}

resource "azurerm_network_interface_application_security_group_association" "ad-asg-asso" {
  for_each = toset(local.asg_associations["ad"])
  network_interface_id          = azurerm_network_interface.ad-nic.id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

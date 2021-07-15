resource "azurerm_network_interface" "ad-nic" {
  name                = "ad-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_vnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "ad" {
  name                = "ad"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = try(local.configuration_yml["ad"].vm_size, "Standard_D2s_v3")
  admin_username      = local.admin_username
  admin_password      = random_password.password.result 
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

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-smalldisk"
    version   = "latest"
  }
}


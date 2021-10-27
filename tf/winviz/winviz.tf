resource "azurerm_network_interface" "winviz-nic" {
  name                = "winviz-nic"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_compute_subnet ? azurerm_subnet.compute[0].id : data.azurerm_subnet.compute[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "win" {
  name                = "winviz"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  size                = try(local.configuration_yml["winviz"].vm_size, "Standard_D4s_v3")
  admin_username      = local.admin_username
  admin_password      = random_password.password.result 
  network_interface_ids = [
    azurerm_network_interface.winviz-nic.id,
  ]

  winrm_listener {
    protocol = "Http"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "21h1-pron-g2"
    version   = "latest"
  }
}


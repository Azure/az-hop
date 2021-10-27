resource "azurerm_network_interface" "winviz-nic" {
  count = local.create_winviz ? 1 : 0
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
  count = local.create_winviz ? 1 : 0
  name                = "winviz"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  size                = try(local.configuration_yml["winviz"].vm_size, "Standard_D4s_v3")
  admin_username      = local.admin_username
  admin_password      = random_password.password.result 
  network_interface_ids = [
    azurerm_network_interface.winviz-nic[0].id,
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

resource "azurerm_network_interface_application_security_group_association" "winviz-asg-asso" {
  for_each = local.create_winviz ? toset(local.asg_associations["winviz"]) : []
  network_interface_id          = azurerm_network_interface.winviz-nic[0].id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

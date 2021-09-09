resource "azurerm_network_interface" "ad-nic" {
  name                = "ad-nic"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_vnet ? azurerm_subnet.ad[0].id : data.azurerm_subnet.ad[0].id
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

resource "azurerm_network_interface_application_security_group_association" "ad-asg-asso" {
  for_each = toset(local.asg_associations["ad"])
  network_interface_id          = azurerm_network_interface.ad-nic.id
  application_security_group_id = local.create_vnet ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

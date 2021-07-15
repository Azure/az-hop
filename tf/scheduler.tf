resource "azurerm_network_interface" "scheduler-nic" {
  name                = "scheduler-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_vnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "scheduler" {
  name                = "scheduler"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = try(local.configuration_yml["scheduler"].vm_size, "Standard_D2s_v3")
  admin_username      = local.admin_username
  network_interface_ids = [
    azurerm_network_interface.scheduler-nic.id,
  ]

  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.internal.public_key_openssh #file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }
}

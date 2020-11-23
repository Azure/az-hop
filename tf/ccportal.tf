resource "azurerm_network_interface" "ccportal-nic" {
  name                = "ccportal-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.admin.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "ccportal" {
  name                = "ccportal"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vm_size                = "Standard_d2s_v3"
  #admin_username      = "hpcadmin"
  network_interface_ids = [
    azurerm_network_interface.ccportal-nic.id,
  ]

  os_profile {
    computer_name  = "ccportal"
    admin_username = "hpcadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/hpcadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  #admin_ssh_key {
  #  username   = "hpcadmin"
  #  public_key = file("~/.ssh/id_rsa.pub")
  #}

  storage_os_disk {
    name              = "ccportal-osdisk"
    create_option     = "FromImage"
    caching              = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "azurecyclecloud"
    offer     = "azure-cyclecloud"
    sku       = "cyclecloud-81"
    version   = "8.1.0"
  }

  plan {
    name = "cyclecloud-81"
    publisher = "azurecyclecloud"
    product = "azure-cyclecloud"
  }

  storage_data_disk {
    lun               = 0
    name              = "ccportal-datadisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 128
  }
}

#  connection {
#    type     = "ssh"
#    host     = azurerm_public_ip.jumpbox-pip.ip_address
#    user     = azurerm_linux_virtual_machine.jumpbox.admin_username
#    private_key = file("~/.ssh/id_rsa")
#  }

#  provisioner "remote-exec" {
#    inline = ["sudo yum install screen -y"]
#  }


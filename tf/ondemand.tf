resource "azurerm_public_ip" "ondemand-pip" {
  name                = "ondemand-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  domain_name_label   = "ondemand${random_string.resource_postfix.result}"
}

resource "azurerm_network_interface" "ondemand-nic" {
  name                = "ondemand-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ondemand-pip.id
  }
}

resource "azurerm_linux_virtual_machine" "ondemand" {
  name                = "ondemand"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_d2s_v3"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.ondemand-nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.internal.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.7"
    version   = "latest"
  }
}

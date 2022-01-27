resource "azurerm_public_ip" "jumpbox-pip" {
  count               = local.allow_public_ip ? 1 : 0
  name                = "jumpbox-pip"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "jumpbox-nic" {
  name                = "jumpbox-nic"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_frontend_subnet ? azurerm_subnet.frontend[0].id : data.azurerm_subnet.frontend[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = local.allow_public_ip ? azurerm_public_ip.jumpbox-pip[0].id : null
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "jumpbox"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  size                = try(local.configuration_yml["jumpbox"].vm_size, "Standard_D2s_v3")
  admin_username      = local.admin_username
  network_interface_ids = [
    azurerm_network_interface.jumpbox-nic.id,
  ]

  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.internal.public_key_openssh
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

  #depends_on = [azurerm_network_interface_application_security_group_association.jumpbox-asg-asso]
}

resource "azurerm_network_interface_application_security_group_association" "jumpbox-asg-asso" {
  for_each = toset(local.asg_associations["jumpbox"])
  network_interface_id          = azurerm_network_interface.jumpbox-nic.id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

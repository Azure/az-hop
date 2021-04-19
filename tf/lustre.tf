locals {
    lustre_rbh_sku = "Standard_D8d_v4"
    lustre_mds_sku = "Standard_D8d_v4"
    lustre_oss_sku = "Standard_D32d_v4"
    lustre_oss_count = 2
    lustre_image_reference = {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7_7-gen2"
        version   = "7.7.2020062401"
    }
}

#
# lustre MDS/MGS VM
#

resource "azurerm_network_interface" "lustre-nic" {
  name                = "lustre-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.admin.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "lustre" {
  name                  = "lustre"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = local.lustre_mds_sku
  network_interface_ids = [
    azurerm_network_interface.lustre-nic.id,
  ]
  
  admin_username = local.admin_username
  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.internal.public_key_openssh
  }

  os_disk {
    name                 = "lustre-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
      publisher = local.lustre_image_reference.publisher
      offer     = local.lustre_image_reference.offer
      sku       = local.lustre_image_reference.sku
      version   = local.lustre_image_reference.version
  }
}

#
# lustre OSS VMs
#

resource "azurerm_network_interface" "lustre-oss-nic" {
  count               = local.lustre_oss_count
  name                = "lustre-oss-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.admin.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "lustre-oss" {
  count                 = local.lustre_oss_count
  name                  = "lustre-oss-${count.index}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = local.lustre_oss_sku
  network_interface_ids = [
    element(azurerm_network_interface.lustre-oss-nic.*.id, count.index)
  ]

  admin_username = local.admin_username
  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.internal.public_key_openssh
  }

  os_disk {
    name                 = "lustre-oss-${count.index}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
      publisher = local.lustre_image_reference.publisher
      offer     = local.lustre_image_reference.offer
      sku       = local.lustre_image_reference.sku
      version   = local.lustre_image_reference.version
  }

  identity {
    type = "SystemAssigned"
  }
}

#
# Robinhood VM
#

resource "azurerm_network_interface" "robinhood-nic" {
  name                = "robinhood-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.admin.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "robinhood" {
  name                  = "robinhood"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = local.lustre_mds_sku
  network_interface_ids = [
    azurerm_network_interface.robinhood-nic.id,
  ]

  admin_username = local.admin_username
  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.internal.public_key_openssh
  }

  os_disk {
    name                 = "robinhood-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
      publisher = local.lustre_image_reference.publisher
      offer     = local.lustre_image_reference.offer
      sku       = local.lustre_image_reference.sku
      version   = local.lustre_image_reference.version
  }
}

locals {
  lustre_image_reference = {
    publisher = "azhpc"
    offer     = "azurehpc-lustre"
    sku       = "azurehpc-lustre-2_12"
    version   = "latest"
  }
}

#
# lustre MDS/MGS VM
#

resource "azurerm_network_interface" "lustre-nic" {
  name                          = "lustre-nic"
  location                      = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name           = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "lustre" {
  name                  = "lustre"
  location              = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name   = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
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

  plan {
    publisher = local.lustre_image_reference.publisher
    product   = local.lustre_image_reference.offer
    name      = local.lustre_image_reference.sku
  }

  #depends_on = [azurerm_network_interface_application_security_group_association.lustre-asg-asso]
}

resource "azurerm_network_interface_application_security_group_association" "lustre-asg-asso" {
  for_each = toset(local.asg_associations["lustre"])
  network_interface_id          = azurerm_network_interface.lustre-nic.id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

#
# lustre OSS VMs
#

resource "azurerm_user_assigned_identity" "lustre-oss" {
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  name = "lustre-oss"
}

resource "azurerm_network_interface" "lustre-oss-nic" {
  count                          = local.lustre_oss_count
  name                           = "lustre-oss-nic-${count.index}"
  location                       = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name            = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  enable_accelerated_networking  = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "lustre-oss" {
  count                 = local.lustre_oss_count
  name                  = "lustre-oss-${count.index}"
  location              = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name   = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
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

  plan {
    publisher = local.lustre_image_reference.publisher
    product   = local.lustre_image_reference.offer
    name      = local.lustre_image_reference.sku
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.lustre-oss.id ]
  }

  #depends_on = [azurerm_network_interface_application_security_group_association.lustre-oss-asg-asso]
}

# Grant read access to the Keyvault for the lustre-oss identity
resource "azurerm_key_vault_access_policy" "lustre-oss" {
  key_vault_id = azurerm_key_vault.azhop.id
  tenant_id    = local.tenant_id
  object_id    = azurerm_user_assigned_identity.lustre-oss.principal_id

  key_permissions = [ "get", "list" ]
  secret_permissions = [ "get", "list" ]
}

# Problem : How to generate associations for all OSS instances as we can't mix count and for_each ???
# Solution : Use a combined flatten list
locals {
  # https://www.daveperrett.com/articles/2021/08/19/nested-for-each-with-terraform/
  # Nested loop over both lists, and flatten the result.
  lustre_oss_asgs = distinct(flatten([
    for oss in range(0, local.lustre_oss_count) : [
      for asg in local.asg_associations["lustre"] : {
        oss = oss
        asg = asg
      }
    ]
  ]))
}

resource "azurerm_network_interface_application_security_group_association" "lustre-oss-asg-asso" {
  # We need a map to use for_each, so we convert our list into a map by adding a unique key:
  for_each = { for entry in local.lustre_oss_asgs: "${entry.oss}.${entry.asg}" => entry }
  network_interface_id          = azurerm_network_interface.lustre-oss-nic[each.value.oss].id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.value.asg].id : data.azurerm_application_security_group.asg[each.value.asg].id
}

#
# Robinhood VM
#

resource "azurerm_network_interface" "robinhood-nic" {
  name                          = "robinhood-nic"
  location                      = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name           = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "robinhood" {
  name                  = "robinhood"
  location              = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name   = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  size                  = local.lustre_rbh_sku
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

  plan {
    publisher = local.lustre_image_reference.publisher
    product   = local.lustre_image_reference.offer
    name      = local.lustre_image_reference.sku
  }
  
  identity {
    type         = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.lustre-oss.id ]
  }

  #depends_on = [azurerm_network_interface_application_security_group_association.robinhood-asg-asso]
}

resource "azurerm_network_interface_application_security_group_association" "robinhood-asg-asso" {
  for_each = toset(local.asg_associations["robinhood"])
  network_interface_id          = azurerm_network_interface.robinhood-nic.id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

#
# lustre MDS/MGS VM
#

resource "azurerm_network_interface" "lustre-nic" {
  count                         = local.lustre_enabled ? 1 : 0
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
  count                 = local.lustre_enabled ? 1 : 0
  name                  = "lustre"
  location              = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name   = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  size                  = local.lustre_mds_sku
  network_interface_ids = [
    azurerm_network_interface.lustre-nic[0].id,
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

  dynamic "source_image_reference" {
    for_each = local.use_lustre_image_id ? [] : [1]
    content {
      publisher = local.lustre_base_image_reference.publisher
      offer     = local.lustre_base_image_reference.offer
      sku       = local.lustre_base_image_reference.sku
      version   = local.lustre_base_image_reference.version
    }
  }

  source_image_id = local.lustre_image_id

  dynamic "plan" {
    for_each = try (length(local.lustre_image_plan.name) > 0, false) ? [1] : []
    content {
        name      = local.lustre_image_plan.name
        publisher = local.lustre_image_plan.publisher
        product   = local.lustre_image_plan.product
    }
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_interface_application_security_group_association" "lustre-asg-asso" {
  for_each                      = local.lustre_enabled ? toset(local.asg_associations["lustre"]) : []
  network_interface_id          = azurerm_network_interface.lustre-nic[0].id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

#
# lustre OSS VMs
#

resource "azurerm_network_interface" "lustre-oss-nic" {
  count                          = local.lustre_enabled ? local.lustre_oss_count : 0
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
  count                 = local.lustre_enabled ? local.lustre_oss_count : 0
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

  dynamic "source_image_reference" {
    for_each = local.use_lustre_image_id ? [] : [1]
    content {
      publisher = local.lustre_base_image_reference.publisher
      offer     = local.lustre_base_image_reference.offer
      sku       = local.lustre_base_image_reference.sku
      version   = local.lustre_base_image_reference.version
    }
  }

  source_image_id = local.lustre_image_id

  dynamic "plan" {
    for_each = try (length(local.lustre_image_plan.name) > 0, false) ? [1] : []
    content {
        name      = local.lustre_image_plan.name
        publisher = local.lustre_image_plan.publisher
        product   = local.lustre_image_plan.product
    }
  }

  identity {
    type         = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

#########################################################################
#  Grant read access to the Keyvault to lustre-oss-*0                   #
#########################################################################
resource "azurerm_key_vault_access_policy" "lustre-oss" {
  count               = local.lustre_enabled ? local.lustre_oss_count : 0
  key_vault_id        = azurerm_key_vault.azhop.id
  tenant_id           = local.tenant_id
  object_id           = length(azurerm_linux_virtual_machine.lustre-oss[count.index].identity[0].principal_id) > 0 ? azurerm_linux_virtual_machine.lustre-oss[count.index].identity[0].principal_id : uuid()

  secret_permissions  = [ "Get", "List" ]
}

# Problem : How to generate associations for all OSS instances as we can't mix count and for_each ???
# Solution : Use a combined flatten list
locals {
  # https://www.daveperrett.com/articles/2021/08/19/nested-for-each-with-terraform/
  # Nested loop over both lists, and flatten the result.
  lustre_oss_asgs = distinct(flatten([
    for oss in range(0, local.lustre_enabled ? local.lustre_oss_count : 0) : [
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
  count                         = local.lustre_enabled ? 1 : 0
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
  count                 = local.lustre_enabled ? 1 : 0
  name                  = "robinhood"
  location              = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name   = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  size                  = local.lustre_rbh_sku
  network_interface_ids = [
    azurerm_network_interface.robinhood-nic[0].id,
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

  dynamic "source_image_reference" {
    for_each = local.use_lustre_image_id ? [] : [1]
    content {
      publisher = local.lustre_base_image_reference.publisher
      offer     = local.lustre_base_image_reference.offer
      sku       = local.lustre_base_image_reference.sku
      version   = local.lustre_base_image_reference.version
    }
  }

  source_image_id = local.lustre_image_id

  dynamic "plan" {
    for_each = try (length(local.lustre_image_plan.name) > 0, false) ? [1] : []
    content {
        name      = local.lustre_image_plan.name
        publisher = local.lustre_image_plan.publisher
        product   = local.lustre_image_plan.product
    }
  }
  
  identity {
    type         = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

#
#  Grant read access to the Keyvault to robinhood
#
resource "azurerm_key_vault_access_policy" "robinhood" {
  count               = local.lustre_enabled ? 1 : 0
  key_vault_id        = azurerm_key_vault.azhop.id
  tenant_id           = local.tenant_id
  object_id           = length(azurerm_linux_virtual_machine.robinhood[0].identity[0].principal_id) > 0 ? azurerm_linux_virtual_machine.robinhood[0].identity[0].principal_id : uuid()
  secret_permissions  = [ "Get", "List" ]
}

resource "azurerm_network_interface_application_security_group_association" "robinhood-asg-asso" {
  for_each                      = local.lustre_enabled ? toset(local.asg_associations["robinhood"]) : []
  network_interface_id          = azurerm_network_interface.robinhood-nic[0].id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}
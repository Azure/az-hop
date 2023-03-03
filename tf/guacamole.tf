resource "azurerm_network_interface" "guacamole-nic" {
  count               = local.enable_remote_winviz ? 1 : 0
  name                = "guacamole-nic"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "guacamole" {
  count               = local.enable_remote_winviz ? 1 : 0
  name                = "guacamole"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  size                = try(local.configuration_yml["guacamole"].vm_size, "Standard_B2ms")
  admin_username      = local.admin_username
  network_interface_ids = [
    azurerm_network_interface.guacamole-nic[0].id,
  ]

  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.internal.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  dynamic "source_image_reference" {
    for_each = local.use_linux_image_id ? [] : [1]
    content {
      publisher = local.linux_base_image_reference.publisher
      offer     = local.linux_base_image_reference.offer
      sku       = local.linux_base_image_reference.sku
      version   = local.linux_base_image_reference.version
    }
  }

  source_image_id = local.linux_image_id

  dynamic "plan" {
    for_each = try (length(local.linux_image_plan.name) > 0, false) ? [1] : []
    content {
        name      = local.linux_image_plan.name
        publisher = local.linux_image_plan.publisher
        product   = local.linux_image_plan.product
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

# Grant read access to the Keyvault for the guacamole identity
resource "azurerm_key_vault_access_policy" "guacamole" {
  count        = local.enable_remote_winviz ? 1 : 0
  key_vault_id = azurerm_key_vault.azhop.id
  tenant_id    = local.tenant_id
  object_id    = length(azurerm_linux_virtual_machine.guacamole[0].identity[0].principal_id) > 0 ? azurerm_linux_virtual_machine.guacamole[0].identity[0].principal_id : uuid()

  secret_permissions = [ "Get", "List" ]
}

resource "azurerm_network_interface_application_security_group_association" "guacamole-asg-asso" {
  for_each = local.enable_remote_winviz ? toset(local.asg_associations["guacamole"]) : []
  network_interface_id          = azurerm_network_interface.guacamole-nic[0].id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

resource "azurerm_public_ip" "ondemand-pip" {
  count               = local.allow_public_ip ? 1 : 0
  name                = "ondemand-pip"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  allocation_method   = "Static"
  domain_name_label   = "ondemand${random_string.resource_postfix.result}"
}

resource "azurerm_network_interface" "ondemand-nic" {
  name                = "ondemand-nic"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_frontend_subnet ? azurerm_subnet.frontend[0].id : data.azurerm_subnet.frontend[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = local.allow_public_ip ? azurerm_public_ip.ondemand-pip[0].id : null
  }
}

resource "azurerm_linux_virtual_machine" "ondemand" {
  name                = "ondemand"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  size                = try(local.configuration_yml["ondemand"].vm_size, "Standard_D4s_v3")
  admin_username      = local.admin_username
  network_interface_ids = [
    azurerm_network_interface.ondemand-nic.id,
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
    for_each = try (length(local.base_image_plan.name) > 0, false) ? [1] : []
    content {
        name      = local.base_image_plan.name
        publisher = local.base_image_plan.publisher
        product   = local.base_image_plan.product
    }
  }

  #depends_on = [azurerm_network_interface_application_security_group_association.ondemand-asg-asso]
}

resource "azurerm_network_interface_application_security_group_association" "ondemand-asg-asso" {
  for_each = toset(local.asg_associations["ondemand"])
  network_interface_id          = azurerm_network_interface.ondemand-nic.id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

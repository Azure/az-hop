#If using an existing AD then get the keyvault and password details for the domain join user
#these values are used to generate a local variable that is passed to the output for use by ansible
data "azurerm_key_vault" "domain_join_password" {
  count               = local.create_ad ? 0 : 1
  name                = local.create_ad ? "foo" : local.configuration_yml["domain"].domain_join_user.password_key_vault_name
  resource_group_name = local.create_ad ? "foo" : local.configuration_yml["domain"].domain_join_user.password_key_vault_resource_group_name
}

data "azurerm_key_vault_secret" "domain_join_password" {
  count        = local.create_ad ? 0 : 1
  name         = local.create_ad ? "foo" : local.configuration_yml["domain"].domain_join_user.password_key_vault_secret_name
  key_vault_id = data.azurerm_key_vault.domain_join_password[0].id
}

resource "azurerm_network_interface" "ad-nic" {
  count               = local.create_ad ? 1 : 0
  name                = "ad-nic"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_ad_subnet ? azurerm_subnet.ad[0].id : data.azurerm_subnet.ad[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "ad" {
  count               = local.create_ad ? 1 : 0
  name                = "ad"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  size                = try(local.configuration_yml["ad"].vm_size, "Standard_D2s_v3")
  admin_username      = local.admin_username
  admin_password      = random_password.password.result
  license_type        = try(local.configuration_yml["ad"].hybrid_benefit, false) ? "Windows_Server" : "None"

  network_interface_ids = [
    azurerm_network_interface.ad-nic[0].id,
  ]

  winrm_listener {
    protocol = "Http"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  dynamic "source_image_reference" {
    for_each = local.use_windows_image_id ? [] : [1]
    content {
      publisher = local.windows_base_image_reference.publisher
      offer     = local.windows_base_image_reference.offer
      sku       = local.windows_base_image_reference.sku
      version   = local.windows_base_image_reference.version
    }
  }

  source_image_id = local.windows_image_id

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_interface_application_security_group_association" "ad-asg-asso" {
  for_each = local.create_ad ? toset(local.asg_associations["ad"]) : []
  network_interface_id          = azurerm_network_interface.ad-nic[0].id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}


## Second AD VM for high availability scenario
resource "azurerm_network_interface" "ad2-nic" {
  count               = local.ad_ha ? 1 : 0
  name                = "ad2-nic"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_ad_subnet ? azurerm_subnet.ad[0].id : data.azurerm_subnet.ad[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "ad2" {
  count               = local.ad_ha ? 1 : 0
  name                = "ad2"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  size                = try(local.configuration_yml["ad"].vm_size, "Standard_D2s_v3")
  admin_username      = local.admin_username
  admin_password      = random_password.password.result
  license_type        = try(local.configuration_yml["ad"].hybrid_benefit, false) ? "Windows_Server" : "None"

  network_interface_ids = [
    azurerm_network_interface.ad2-nic[0].id,
  ]

  winrm_listener {
    protocol = "Http"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  dynamic "source_image_reference" {
    for_each = local.use_windows_image_id ? [] : [1]
    content {
      publisher = local.windows_base_image_reference.publisher
      offer     = local.windows_base_image_reference.offer
      sku       = local.windows_base_image_reference.sku
      version   = local.windows_base_image_reference.version
    }
  }

  source_image_id = local.windows_image_id

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_interface_application_security_group_association" "ad2-asg-asso" {
  for_each = local.ad_ha ? toset(local.asg_associations["ad"]) : []
  network_interface_id          = azurerm_network_interface.ad2-nic[0].id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}


#adding explicit moved blocks to ensure clean migrations for previously deployed environments
#https://developer.hashicorp.com/terraform/language/modules/develop/refactoring#enabling-count-or-for_each-for-a-resource

moved {
  from = azurerm_network_interface.ad-nic
  to   = azurerm_network_interface.ad-nic[0]
}

moved {
  from = azurerm_windows_virtual_machine.ad
  to   = azurerm_windows_virtual_machine.ad[0]
}


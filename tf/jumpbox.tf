resource "azurerm_public_ip" "jumpbox-pip" {
  count               = local.allow_public_ip && local.jumpbox_enabled ? 1 : 0
  name                = "jumpbox-pip"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "jumpbox-nic" {
  count               = local.jumpbox_enabled ? 1 : 0
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
  count               = local.jumpbox_enabled ? 1 : 0
  name                = "jumpbox"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  size                = try(local.configuration_yml["jumpbox"].vm_size, "Standard_D2s_v3")
  admin_username      = local.admin_username
  network_interface_ids = [
    azurerm_network_interface.jumpbox-nic[0].id,
  ]
  # Set cloud-init only if ssh port is not default
  custom_data = local.jumpbox_ssh_port != "22" ? data.local_file.ci_jumpbox.content_base64 : filebase64("cloud-init/empty.yml")
  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.internal.public_key_openssh
  }

  identity {
    type         = "SystemAssigned"
    //type         = "UserAssigned"
    //identity_ids = [ azurerm_user_assigned_identity.azure_monitor_identity.id ]
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

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_network_interface_application_security_group_association" "jumpbox-asg-asso" {
  for_each = local.jumpbox_enabled ? toset(local.asg_associations["jumpbox"]) : []
  network_interface_id          = azurerm_network_interface.jumpbox-nic[0].id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

resource "azurerm_virtual_machine_extension" "AzureMonitorLinuxAgent" {
  depends_on = [
    azurerm_linux_virtual_machine.jumpbox
    #azurerm_user_assigned_identity.azure_monitor_identity
  ]
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.jumpbox[0].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

/*  settings                   = <<SETTINGS
  {
    "authentication": {
      "managedIdentity": {
        "identifier-name": "mi_res_id",
        "identifier-value": "${azurerm_user_assigned_identity.azure_monitor_identity.id}" 
      }
    }
  }
  SETTINGS*/
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_vm_metrics" {
    name                = "vm-data-collection-ra"
    target_resource_id = azurerm_linux_virtual_machine.jumpbox[0].id
    data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_data_collection_rule.id
    description = "Data Collection Rule Association for VM Metrics"
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_vm_insights" {
    name                = "vm-insights-collection-ra"
    target_resource_id = azurerm_linux_virtual_machine.jumpbox[0].id
    data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights_collection_rule.id
    description = "Data Collection Rule Association for VM Insights"
}

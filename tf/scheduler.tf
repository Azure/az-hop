resource "azurerm_network_interface" "scheduler-nic" {
  name                = "scheduler-nic"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "scheduler" {
  name                = "scheduler"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  size                = try(local.configuration_yml["scheduler"].vm_size, "Standard_D2s_v3")
  admin_username      = local.admin_username
  network_interface_ids = [
    azurerm_network_interface.scheduler-nic.id,
  ]
  identity {
    type         = "SystemAssigned"
  }

  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.internal.public_key_openssh #file("~/.ssh/id_rsa.pub")
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

resource "azurerm_virtual_machine_extension" "AzureMonitorLinuxAgent_sched" {
  depends_on = [
    azurerm_linux_virtual_machine.scheduler
  ]
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.scheduler.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_network_interface_application_security_group_association" "scheduler-asg-asso" {
  for_each = toset(local.asg_associations["scheduler"])
  network_interface_id          = azurerm_network_interface.scheduler-nic.id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_sched_metrics" {
    name                = "sched-data-collection-ra"
    target_resource_id = azurerm_linux_virtual_machine.scheduler.id
    data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_data_collection_rule.id
    description = "Scheduler Data Collection Rule Association for VM Metrics"
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_sched_insights" {
    name                = "sched-insights-collection-ra"
    target_resource_id = azurerm_linux_virtual_machine.scheduler.id
    data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights_collection_rule.id
    description = "Scheduler Data Collection Rule Association for VM Insights"
}

resource "azurerm_network_interface" "scheduler-nic" {
  name                = "${local.scheduler_name}-nic"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "scheduler" {
  name                = local.scheduler_name
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

resource "azurerm_network_interface_application_security_group_association" "scheduler-asg-asso" {
  for_each = toset(local.asg_associations["scheduler"])
  network_interface_id          = azurerm_network_interface.scheduler-nic.id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

resource "azurerm_virtual_machine_extension" "AzureMonitorLinuxAgent_sched" {
  count                      = local.ama_install ? 1 : 0
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.scheduler.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_sched_metrics" {
    count               = local.monitor ? 1 : 0
    name                = "sched-data-collection-ra"
    target_resource_id = azurerm_linux_virtual_machine.scheduler.id
    data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_data_collection_rule[0].id
    description = "Scheduler Data Collection Rule Association for VM Metrics"
}

resource "azurerm_monitor_data_collection_rule_association" "dcra_sched_insights" {
    count               = local.monitor ? 1 : 0
    name                = "sched-insights-collection-ra"
    target_resource_id = azurerm_linux_virtual_machine.scheduler.id
    data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights_collection_rule[0].id
    description = "Scheduler Data Collection Rule Association for VM Insights"
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "sched_volume_alert" {
    count = local.create_alerts ? 1 : 0
    name = "sched-volume-alert"
    location = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
    resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name


    evaluation_frequency = "PT5M"
    window_duration = "PT5M"
    scopes = [azurerm_linux_virtual_machine.scheduler.id]
    severity = 3

    criteria {
        query = <<-QUERY
          let mountpoints = dynamic(${local.mountpoints_str});
          InsightsMetrics
          | where TimeGenerated >= ago(5min) and Name == "FreeSpacePercentage" and Val <= ${local.local_vol_threshold} and not(Tags has_any (mountpoints) )
          | project TimeGenerated, Computer, Name, Val, Tags, _ResourceId
          | summarize arg_max(TimeGenerated, *) by Tags
          | project Tags, Name, Val, Computer, _ResourceId
          QUERY
        time_aggregation_method = "Count"
        operator = "GreaterThan"
        threshold = 0
        failing_periods {
            minimum_failing_periods_to_trigger_alert = 1
            number_of_evaluation_periods = 1
        }
    }

    auto_mitigation_enabled = true
    description = "Alert when the volumes of the scheduler VM is above ${100 - local.local_vol_threshold}%"
    display_name = "scheduler volumes full"
    enabled = true
    query_time_range_override = "P2D"

    action {
        action_groups = [azurerm_monitor_action_group.azhop_action_group[0].id]
    }
}

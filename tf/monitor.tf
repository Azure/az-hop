resource "azurerm_log_analytics_workspace" "azhop_workspace" {
    count               = local.create_log_analytics_workspace ? 1 : 0
    name                = "azhop-${random_string.resource_postfix.result}-ws"
    location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
    resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
    sku                 = "PerGB2018"
    retention_in_days   = 30
}

resource "azurerm_monitor_action_group" "azhop_action_group" {
  count               = local.create_alerts ? 1 : 0
  name                = "azhop-${random_string.resource_postfix.result}-ag"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  short_name          = "azhop-ag" # Need to be 12 characters or less
  email_receiver {
    name         = "azhop-email-receiver"
    email_address = local.alert_email
  }
}

resource "azurerm_monitor_data_collection_rule" "vm_data_collection_rule" {
  count               = local.create_log_analytics_workspace ? 1 : 0
  name                = "vm-data-collection-rule"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  kind = "Linux"
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.azhop_workspace[0].id
      name = "vm-logs"
    }
    azure_monitor_metrics {
      name = "vm-metrics"
    }
  }
  data_flow {
    streams = ["Microsoft-InsightsMetrics"]
    destinations = ["vm-metrics"]
  }
   data_flow {
    streams = ["Microsoft-Syslog"]
    destinations = ["vm-logs"]
  }

  data_sources {
    syslog {
      facility_names = ["daemon",
                        "auth",
                        "authpriv",
                        "cron",
                        "kern",
                        "lpr",
                        "mail",
                        "mark",
                        "news",
                        "syslog",
                        "user",
                        "uucp",
                        "local0",
                        "local1",
                        "local2",
                        "local3",
                        "local4",
                        "local5",
                        "local6",
                        "local7"]
      log_levels = ["Debug",
                    "Info",
                    "Notice",
                    "Warning",
                    "Error",
                    "Critical",
                    "Alert",
                    "Emergency"]
      streams = ["Microsoft-Syslog"]
      name = "vm-syslog"
    }
  }
}

resource "azurerm_monitor_data_collection_rule" "vm_insights_collection_rule" {
  count               = local.create_log_analytics_workspace ? 1 : 0
  name                = "vm-insights-collection-rule"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  kind = "Linux"
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.azhop_workspace[0].id
      name = "vm-insights-logs"
    }
  }
  data_flow {
    streams = ["Microsoft-InsightsMetrics"]
    destinations = ["vm-insights-logs"]
  }

  data_sources {
    performance_counter {
        streams                       = ["Microsoft-InsightsMetrics"]
        sampling_frequency_in_seconds = 60
        counter_specifiers            = ["\\VmInsights\\DetailedMetrics"
                                         ]
        name                          = "vm-insights"
    }
  }
}

resource "azurerm_monitor_metric_alert" "vm_availability_alert" {
  count               = local.create_alerts ? 1 : 0
  name                = "vm-availability-alert"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  scopes              = [local.create_rg ? azurerm_resource_group.rg[0].id : data.azurerm_resource_group.rg[0].id]
  description         = "Alert when VM is not available"
  severity            = 3
  enabled             = true
  frequency           = "PT15M"
  window_size         = "PT15M"
  target_resource_type = "Microsoft.Compute/virtualMachines"
  target_resource_location = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }
  action {
    action_group_id = azurerm_monitor_action_group.azhop_action_group[0].id
  }
}


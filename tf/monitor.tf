resource "azurerm_log_analytics_workspace" "azhop_workspace" { 
    name                = "azhop-${random_string.resource_postfix.result}-ws"
    location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
    resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
    sku                 = "PerGB2018"
    retention_in_days   = 30
}
/*
resource "azurerm_user_assigned_identity" "azure_monitor_identity" {
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  name                = "azure-monitor-identity"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
}
*/
resource "azurerm_monitor_action_group" "azhop_action_group" {
  name                = "azhop-ag"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  short_name          = "azhop-ag"
  email_receiver {
    name         = "azhop-email-receiver"
    email_address = "egallardo@microsoft.com" #need to make this into a variable - potentially can make alerting optional as well
  }
}

resource "azurerm_monitor_data_collection_rule" "vm_data_collection_rule" {
  name                = "vm-data-collection-rule"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  kind = "Linux"
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.azhop_workspace.id
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

    performance_counter {
        streams                       = ["Microsoft-InsightsMetrics"]
        sampling_frequency_in_seconds = 10
        counter_specifiers            = [
                                "\\Processor Information(_Total)\\% Processor Time",
                                "\\Processor Information(_Total)\\% Privileged Time",
                                "\\Processor Information(_Total)\\% User Time",
                                "\\Processor Information(_Total)\\Processor Frequency",
                                "\\System\\Processes",
                                "\\Process(_Total)\\Thread Count",
                                "\\Process(_Total)\\Handle Count",
                                "\\System\\System Up Time",
                                "\\System\\Context Switches/sec",
                                "\\System\\Processor Queue Length",
                                "\\Memory\\% Committed Bytes In Use",
                                "\\Memory\\Available Bytes",
                                "\\Memory\\Committed Bytes",
                                "\\Memory\\Cache Bytes",
                                "\\Memory\\Pool Paged Bytes",
                                "\\Memory\\Pool Nonpaged Bytes",
                                "\\Memory\\Pages/sec",
                                "\\Memory\\Page Faults/sec",
                                "\\Process(_Total)\\Working Set",
                                "\\Process(_Total)\\Working Set - Private",
                                "\\LogicalDisk(_Total)\\% Disk Time",
                                "\\LogicalDisk(_Total)\\% Disk Read Time",
                                "\\LogicalDisk(_Total)\\% Disk Write Time",
                                "\\LogicalDisk(_Total)\\% Idle Time",
                                "\\LogicalDisk(_Total)\\Disk Bytes/sec",
                                "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
                                "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
                                "\\LogicalDisk(_Total)\\Disk Transfers/sec",
                                "\\LogicalDisk(_Total)\\Disk Reads/sec",
                                "\\LogicalDisk(_Total)\\Disk Writes/sec",
                                "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",
                                "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
                                "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
                                "\\LogicalDisk(_Total)\\Avg. Disk Queue Length",
                                "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length",
                                "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length",
                                "\\LogicalDisk(_Total)\\% Free Space",
                                "\\LogicalDisk(_Total)\\Free Megabytes",
                                "\\Network Interface(*)\\Bytes Total/sec",
                                "\\Network Interface(*)\\Bytes Sent/sec",
                                "\\Network Interface(*)\\Bytes Received/sec",
                                "\\Network Interface(*)\\Packets/sec",
                                "\\Network Interface(*)\\Packets Sent/sec",
                                "\\Network Interface(*)\\Packets Received/sec",
                                "\\Network Interface(*)\\Packets Outbound Errors",
                                "\\Network Interface(*)\\Packets Received Errors"
        ]
        name                          = "vm-counters"
    }
  }
}

resource "azurerm_monitor_data_collection_rule" "vm_insights_collection_rule" {
  name                = "vm-insights-collection-rule"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  kind = "Linux"
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.azhop_workspace.id
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
  name                = "vm-availability-alert"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  scopes              = [local.create_rg ? azurerm_resource_group.rg[0].id : data.azurerm_resource_group.rg[0].id]
  description         = "Alert when VM is not available"
  severity            = 3
  enabled             = true
  frequency           = "PT5M"
  window_size         = "PT5M"
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
    action_group_id = azurerm_monitor_action_group.azhop_action_group.id
  }
}

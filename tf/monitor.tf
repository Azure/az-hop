resource "azurerm_log_analytics_workspace" "azhop_workspace" { 
    name                = "azhop-${random_string.resource_postfix.result}-ws"
    location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
    resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
    sku                 = "PerGB2018"
    retention_in_days   = 30
}

resource "azurerm_user_assigned_identity" "azure_monitor_identity" {
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  name                = "azure-monitor-identity"
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
}

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
        counter_specifiers            = ["*"]
        name                          = "vm-counters"
    }
  }
}


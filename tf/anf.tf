resource "azurerm_netapp_account" "azhop" {
  count = local.create_anf ? 1 : 0
  name                = "azhop-${random_string.resource_postfix.result}"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  dynamic "active_directory" {
    for_each = local.anf_dual_protocol ? [1] : []
    content {
      username            = local.domain_join_user
      password            = local.domain_join_password
      smb_server_name     = "anf"
      dns_servers         = local.private_dns_servers
      domain              = local.domain_name
      organizational_unit = local.domain_join_ou
    }
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_netapp_pool" "anfpool" {
  count = local.create_anf ? 1 : 0
  name                = "anfpool-${random_string.resource_postfix.result}"
  account_name        = azurerm_netapp_account.azhop[0].name
  location            = azurerm_netapp_account.azhop[0].location
  resource_group_name = azurerm_netapp_account.azhop[0].resource_group_name
  service_level       = local.homefs_service_level
  size_in_tb          = local.homefs_size_tb
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "azurerm_netapp_volume" "home" {
  count = local.create_anf ? 1 : 0
  name                = "anfhome"
  location            = azurerm_netapp_account.azhop[0].location
  resource_group_name = azurerm_netapp_account.azhop[0].resource_group_name
  account_name        = azurerm_netapp_account.azhop[0].name
  pool_name           = azurerm_netapp_pool.anfpool[0].name
  volume_path         = "home-${random_string.resource_postfix.result}"
  service_level       = local.homefs_service_level
  subnet_id           = local.create_netapp_subnet ? azurerm_subnet.netapp[0].id : data.azurerm_subnet.netapp[0].id
  protocols           = local.anf_dual_protocol ?  ["NFSv3", "CIFS"] : ["NFSv3"]
  security_style      = "Unix"
  storage_quota_in_gb = local.homefs_size_tb * 1024

  export_policy_rule {
    rule_index        = 1 
    allowed_clients   = [ "0.0.0.0/0" ]
    unix_read_write   = true
    protocols_enabled = [ "NFSv3" ]
    root_access_enabled = true
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }

  depends_on = [
    azurerm_subnet.netapp,
    data.azurerm_subnet.netapp
  ]
}

resource "azurerm_monitor_metric_alert" "anf_alert" {
  count = local.create_anf && local.create_alerts ? 1 : 0
  name                = "anf-alert-${random_string.resource_postfix.result}"
  resource_group_name = azurerm_netapp_account.azhop[0].resource_group_name
  scopes              = [azurerm_netapp_volume.home[0].id]
  description         = "Alert when ANF volume usage exceeds ${local.anf_vol_threshold}%"
  severity            = 3
  enabled             = true
  frequency           = "PT1M"
  window_size         = "PT5M"
  target_resource_type = "Microsoft.NetApp/netAppAccounts/capacityPools/volumes"

  criteria {
    metric_namespace = "Microsoft.NetApp/netAppAccounts/capacityPools/volumes"
    metric_name      = "VolumeConsumedSizePercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = local.anf_vol_threshold
  }
  action {
    action_group_id = azurerm_monitor_action_group.azhop_action_group[0].id
  }
}


resource "azurerm_storage_account" "nfsfiles" {
    count                    = local.create_nfsfiles ? 1 : 0
    name                     = "nfsfiles${random_string.resource_postfix.result}"
    resource_group_name      = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
    location                 = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
    account_kind             = "FileStorage"
    account_tier             = "Premium"
    account_replication_type = "LRS"
    cross_tenant_replication_enabled = false
    public_network_access_enabled = true
    shared_access_key_enabled = true
    large_file_share_enabled = true
    min_tls_version          = "TLS1_2"
    access_tier              = "Hot"
    enable_https_traffic_only = false

    share_properties {
      smb {
        multichannel_enabled = true
      }
      retention_policy {
        days = 7
      }
    }

  # Grant acccess only from the admin and compute subnets
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = local.grant_access_from
    virtual_network_subnet_ids = [local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id,
                                  local.create_compute_subnet ? azurerm_subnet.compute[0].id : data.azurerm_subnet.compute[0].id,
                                  local.create_frontend_subnet ? azurerm_subnet.frontend[0].id : data.azurerm_subnet.frontend[0].id
                                  ]
  }
}

resource "azurerm_storage_share" "nfsFilesHome" {
    count                = local.create_nfsfiles ? 1 : 0
    name                 = "nfshome"
    storage_account_name = azurerm_storage_account.nfsfiles[0].name
    access_tier          = "Premium"
    enabled_protocol     = "NFS"
    # root_squash          = NoRootSquash # Not supported in Terraform
    quota                = local.azure_files_size
}
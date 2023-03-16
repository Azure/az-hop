resource "azurerm_maintenance_configuration" "ccportal" {
  count                     = local.guest_os_patching ? 1 : 0
  name                      = "ccportal-mc"
  location                  = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name       = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  scope                     = "InGuestPatch"
  in_guest_user_patch_mode  = "User"

  window {
    start_date_time = formatdate("YYYY-MM-DD hh:mm", timeadd(timestamp(), "4h"))
    time_zone       = "UTC"
    recur_every     = "Day"
  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include    = ["Critical", "Security"]
      package_names_mask_to_include = ["*"]
      package_names_mask_to_exclude = ["cyclecloud"]
    }
  }
}

resource "azurerm_maintenance_configuration" "ondemand" {
  count                     = local.guest_os_patching ? 1 : 0
  name                      = "ondemand-mc"
  location                  = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name       = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  scope                     = "InGuestPatch"
  in_guest_user_patch_mode  = "User"

  window {
    start_date_time = formatdate("YYYY-MM-DD hh:mm", timeadd(timestamp(), "4h"))
    time_zone       = "UTC"
    recur_every     = "Day"
  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include    = ["Critical", "Security"]
      package_names_mask_to_include = ["*"]
      package_names_mask_to_exclude = ["kernel*", "kmod*", "amlfs*", "ondemand*"]
    }
  }
}

resource "azurerm_maintenance_configuration" "azhop" {
  count                     = local.guest_os_patching ? 1 : 0
  name                      = "azhop-mc"
  location                  = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name       = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  scope                     = "InGuestPatch"
  in_guest_user_patch_mode  = "User"

  window {
    start_date_time = formatdate("YYYY-MM-DD hh:mm", timeadd(timestamp(), "4h"))
    time_zone       = "UTC"
    recur_every     = "Day"
  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include    = ["Critical", "Security"]
      package_names_mask_to_include = ["*"]
    }
  }
}

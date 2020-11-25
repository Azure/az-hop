resource "local_file" "AnsibleInventory" { 
  content = templatefile("playbooks/inventory.tmpl",
   {
      jumpbox-pip = azurerm_public_ip.jumpbox-pip.ip_address,
      jumpbox-user = azurerm_linux_virtual_machine.jumpbox.admin_username,
      scheduler-ip = azurerm_network_interface.scheduler-nic.private_ip_address,
      scheduler-user = azurerm_linux_virtual_machine.scheduler.admin_username,
      ondemand-fqdn  = azurerm_public_ip.ondemand-pip.fqdn,
      ondemand-ip    = azurerm_network_interface.ondemand-nic.private_ip_address,
      ondemand-user  = azurerm_linux_virtual_machine.ondemand.admin_username,
      ccportal-ip = azurerm_network_interface.ccportal-nic.private_ip_address,
      ad-ip          = azurerm_network_interface.ad-nic.private_ip_address,
      ad-passwd      = azurerm_windows_virtual_machine.ad.admin_password,
      anf-home-ip    = element(azurerm_netapp_volume.home.mount_ip_addresses, 0),
      anf-home-path  = azurerm_netapp_volume.home.volume_path,
    }
  )
  filename = "playbooks/inventory"
}

resource "local_file" "OpenOnDemandOverrides" {
  content = templatefile("playbooks/ood-overrides.yml.tmpl",
    {
      jumpbox-pip    = azurerm_public_ip.jumpbox-pip.ip_address,
      jumpbox-user   = azurerm_linux_virtual_machine.jumpbox.admin_username,
      scheduler-ip   = azurerm_network_interface.scheduler-nic.private_ip_address,
      scheduler-user = azurerm_linux_virtual_machine.scheduler.admin_username,
      ondemand-fqdn  = azurerm_public_ip.ondemand-pip.fqdn,
      ondemand-ip    = azurerm_network_interface.ondemand-nic.private_ip_address,
      ondemand-user  = azurerm_linux_virtual_machine.ondemand.admin_username,
      ad-ip          = azurerm_network_interface.ad-nic.private_ip_address,
      ad-passwd      = azurerm_windows_virtual_machine.ad.admin_password,
      anf-home-ip    = element(azurerm_netapp_volume.home.mount_ip_addresses, 0),
      anf-home-path  = azurerm_netapp_volume.home.volume_path,
    }
  )
  filename = "playbooks/ood-overrides.yml"
}

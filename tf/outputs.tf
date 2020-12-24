resource "local_file" "AnsibleInventory" { 
  content = templatefile("${local.playbooks_template_dir}/inventory.tmpl",
   {
      jumpbox-pip       = azurerm_public_ip.jumpbox-pip.ip_address
      jumpbox-user      = azurerm_linux_virtual_machine.jumpbox.admin_username
      scheduler-ip      = azurerm_network_interface.scheduler-nic.private_ip_address
      scheduler-user    = azurerm_linux_virtual_machine.scheduler.admin_username
      ondemand-fqdn     = azurerm_public_ip.ondemand-pip.fqdn
      ondemand-ip       = azurerm_network_interface.ondemand-nic.private_ip_address
      ondemand-user     = azurerm_linux_virtual_machine.ondemand.admin_username
      ccportal-ip       = azurerm_network_interface.ccportal-nic.private_ip_address
      ad-ip             = azurerm_network_interface.ad-nic.private_ip_address
      ad-passwd         = azurerm_windows_virtual_machine.ad.admin_password
      anf-home-ip       = element(azurerm_netapp_volume.home.mount_ip_addresses, 0)
      anf-home-path     = azurerm_netapp_volume.home.volume_path
      admin-username    = local.admin_username
      ad_join_password  = random_password.password.result
    }
  )
  filename = "${local.playbook_root_dir}/inventory"
}

resource "local_file" "global_variables" {
  sensitive_content = templatefile("${local.playbooks_template_dir}/global_variables.tmpl",
    {
      admin_username = local.admin_username
      ssh_public_key = tls_private_key.internal.public_key_openssh
      cc_password    = azurerm_windows_virtual_machine.ad.admin_password
      cc_storage     = azurerm_storage_account.deployhpc.name
      region         = local.location
      resource_group = local.resource_group
      users_file     = local.configuration_file
    }
  )
  filename = "${local.playbook_root_dir}/group_vars/all.yml"

}

resource "local_file" "connect_script" {
  sensitive_content = templatefile("${local.playbooks_template_dir}/connect.tmpl",
    {
      jumpbox-pip       = azurerm_public_ip.jumpbox-pip.ip_address,
      jumpbox-user      = azurerm_linux_virtual_machine.jumpbox.admin_username,
    }
  )
  filename = "${path.root}/../bin/connect"
  file_permission = 0755
}

resource "local_file" "packer" {
  content = templatefile("${local.packer_root_dir}/templates/options.json.tmpl",
    {
      subscription_id = data.azurerm_subscription.primary.subscription_id
      resource_group  = local.resource_group
    }
  )
  filename = "${local.packer_root_dir}/options.json"
}


output "ondemand_fqdn" {
  value = azurerm_public_ip.ondemand-pip.fqdn
}

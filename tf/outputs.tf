resource "local_file" "AnsibleInventory" { 
  content = templatefile("${local.playbooks_template_dir}/inventory.tmpl",
   {
      jumpbox-pip       = azurerm_public_ip.jumpbox-pip.ip_address
      jumpbox-user      = azurerm_linux_virtual_machine.jumpbox.admin_username
      scheduler-ip      = azurerm_network_interface.scheduler-nic.private_ip_address
      scheduler-user    = azurerm_linux_virtual_machine.scheduler.admin_username
      ondemand-pip      = azurerm_public_ip.ondemand-pip.ip_address
      ondemand-user     = azurerm_linux_virtual_machine.ondemand.admin_username
      ccportal-ip       = azurerm_network_interface.ccportal-nic.private_ip_address
      ad-ip             = azurerm_network_interface.ad-nic.private_ip_address
      ad-passwd         = azurerm_windows_virtual_machine.ad.admin_password
      lustre-user       = azurerm_linux_virtual_machine.lustre.admin_username
      lustre-oss-count  = local.lustre_oss_count
    }
  )
  filename = "${local.playbook_root_dir}/inventory"
}

resource "local_file" "global_variables" {
  sensitive_content = templatefile("${local.playbooks_template_dir}/global_variables.tmpl",
    {
      admin_username      = local.admin_username
      ssh_public_key      = tls_private_key.internal.public_key_openssh
      cc_storage          = azurerm_storage_account.azhop.name
      compute_subnetid    = local.create_vnet ? "${azurerm_subnet.compute[0].resource_group_name}/${azurerm_subnet.compute[0].virtual_network_name}/${azurerm_subnet.compute[0].name}" : "${data.azurerm_subnet.compute[0].resource_group_name}/${data.azurerm_subnet.compute[0].virtual_network_name}/${data.azurerm_subnet.compute[0].name}"
      region              = local.location
      resource_group      = local.resource_group
      config_file         = local.configuration_file
      homedir_mountpoint  = local.homedir_mountpoint
      ad-ip               = azurerm_network_interface.ad-nic.private_ip_address
      anf-home-ip         = element(azurerm_netapp_volume.home.mount_ip_addresses, 0)
      anf-home-path       = azurerm_netapp_volume.home.volume_path
      ondemand-fqdn       = azurerm_public_ip.ondemand-pip.fqdn
      subscription_id     = data.azurerm_subscription.primary.subscription_id
      key_vault           = azurerm_key_vault.azhop.name
      sig_name            = azurerm_shared_image_gallery.sig.name
      lustre_hsm_storage_account = ( local.lustre_archive_account != null ? local.lustre_archive_account : azurerm_storage_account.azhop.name )
      lustre_hsm_storage_container = ( local.lustre_archive_account != null ? local.configuration_yml["lustre"]["hsm"]["storage_container"] : azurerm_storage_container.lustre_archive[0].name )
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

resource "local_file" "get_secret_script" {
  sensitive_content = templatefile("${local.playbooks_template_dir}/get_secret.tmpl",
    {
      key_vault          = azurerm_key_vault.azhop.name
    }
  )
  filename = "${path.root}/../bin/get_secret"
  file_permission = 0755
}

resource "local_file" "packer" {
  content = templatefile("${local.packer_root_dir}/templates/options.json.tmpl",
    {
      subscription_id = data.azurerm_subscription.primary.subscription_id
      resource_group  = local.resource_group
      location        = local.location
      sig_name        = azurerm_shared_image_gallery.sig.name
    }
  )
  filename = "${local.packer_root_dir}/options.json"
}

output "ondemand_fqdn" {
  value = azurerm_public_ip.ondemand-pip.fqdn
}

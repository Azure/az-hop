resource "local_file" "AnsibleInventory" { 
  content = templatefile("${local.playbooks_template_dir}/inventory.tmpl",
   {
      jumpbox-pip       = azurerm_public_ip.jumpbox-pip.ip_address
      jumpbox-user      = azurerm_linux_virtual_machine.jumpbox.admin_username
      ad-ip             = azurerm_network_interface.ad-nic.private_ip_address
      ad-passwd         = azurerm_windows_virtual_machine.ad.admin_password
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
      ad-ip               = azurerm_network_interface.ad-nic.private_ip_address
      key_vault           = azurerm_key_vault.azhop.name
    }
  )
  filename = "${local.playbook_root_dir}/group_vars/all.yml"
}

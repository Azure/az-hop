resource "local_file" "AnsibleInventory" { 
  content = templatefile("${local.playbooks_template_dir}/inventory.tmpl",
   {
      jumpbox-pip       = local.allow_public_ip ? azurerm_public_ip.jumpbox-pip[0].ip_address : azurerm_network_interface.jumpbox-nic.private_ip_address
      jumpbox-user      = azurerm_linux_virtual_machine.jumpbox.admin_username
      winviz-ip         = azurerm_network_interface.winviz-nic.private_ip_address
      ad-passwd         = azurerm_windows_virtual_machine.ad.admin_password
    }
  )
  filename = "${local.playbook_root_dir}/inventory_winviz"
}
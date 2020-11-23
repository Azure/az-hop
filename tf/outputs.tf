### The Ansible inventory file
resource "local_file" "AnsibleInventory" {
 content = templatefile("playbooks/inventory.tmpl",
 {
  jumpbox-pip = azurerm_public_ip.jumpbox-pip.ip_address,
  jumpbox-user = azurerm_linux_virtual_machine.jumpbox.admin_username,
  scheduler-ip = azurerm_network_interface.scheduler-nic.private_ip_address,
  scheduler-user = azurerm_linux_virtual_machine.scheduler.admin_username,
  ad-ip = azurerm_network_interface.ad-nic.private_ip_address,
  ad-passwd = azurerm_windows_virtual_machine.ad.admin_password,
 }
 )
 filename = "playbooks/inventory"
}

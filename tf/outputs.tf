resource "local_file" "AnsibleInventory" { 
  content = templatefile("${local.playbooks_template_dir}/inventory.tmpl",
   {
      jumpbox-pip       = local.allow_public_ip ? azurerm_public_ip.jumpbox-pip[0].ip_address : azurerm_network_interface.jumpbox-nic.private_ip_address
      jumpbox-user      = azurerm_linux_virtual_machine.jumpbox.admin_username
      jumpbox-ssh-port  = local.jumpbox_ssh_port
      ad-ip             = azurerm_network_interface.ad-nic.private_ip_address
      ad-passwd         = azurerm_windows_virtual_machine.ad.admin_password
      lustre-oss-count  = local.lustre_oss_count
      winviz-ip         = try(azurerm_network_interface.winviz-nic[0].private_ip_address, "0.0.0.0")
    }
  )
  filename = "${local.playbook_root_dir}/inventory"
}
resource "local_file" "CISInventory" { 
  content = templatefile("${local.playbooks_template_dir}/inventory.cis.tmpl",
   {
      lustre-oss-count  = local.lustre_oss_count
    }
  )
  filename = "${local.playbook_root_dir}/inventory.cis.yml"
}

resource "local_file" "global_variables" {
  sensitive_content = templatefile("${local.playbooks_template_dir}/global_variables.tmpl",
    {
      azure_environment   = local.azure_environment
      key_vault_suffix    = local.key_vault_suffix
      blob_storage_suffix = local.blob_storage_suffix
      admin_username      = local.admin_username
      ssh_public_key      = tls_private_key.internal.public_key_openssh
      cc_storage          = azurerm_storage_account.azhop.name
      compute_subnetid    = local.create_compute_subnet ? "${azurerm_subnet.compute[0].resource_group_name}/${azurerm_subnet.compute[0].virtual_network_name}/${azurerm_subnet.compute[0].name}" : "${data.azurerm_subnet.compute[0].resource_group_name}/${data.azurerm_subnet.compute[0].virtual_network_name}/${data.azurerm_subnet.compute[0].name}"
      region              = local.location
      resource_group      = local.resource_group
      config_file         = local.configuration_file
      homedir_mountpoint  = local.homedir_mountpoint
      ad-ip               = azurerm_network_interface.ad-nic.private_ip_address
      anf-home-ip         = local.create_anf ? element(azurerm_netapp_volume.home[0].mount_ip_addresses, 0) : local.configuration_yml["mounts"]["home"]["server"]
      anf-home-path       = local.create_anf ? azurerm_netapp_volume.home[0].volume_path : local.configuration_yml["mounts"]["home"]["export"]
      ondemand-fqdn       = local.allow_public_ip ? azurerm_public_ip.ondemand-pip[0].fqdn : try( local.configuration_yml["ondemand"]["fqdn"], azurerm_network_interface.ondemand-nic.private_ip_address)
      subscription_id     = data.azurerm_subscription.primary.subscription_id
      tenant_id           = data.azurerm_subscription.primary.tenant_id
      key_vault           = azurerm_key_vault.azhop.name
      sig_name            = azurerm_shared_image_gallery.sig.name
      lustre_hsm_storage_account = ( local.lustre_archive_account != null ? local.lustre_archive_account : azurerm_storage_account.azhop.name )
      lustre_hsm_storage_container = ( local.lustre_archive_account != null ? local.configuration_yml["lustre"]["hsm"]["storage_container"] : azurerm_storage_container.lustre_archive[0].name )
      mysql-fqdn        = local.slurm_accounting ? azurerm_mysql_server.mysql[0].fqdn : ""
      mysql-user        = local.slurm_accounting_admin_user
      jumpbox-ssh-port  = local.jumpbox_ssh_port
    }
  )
  filename = "${local.playbook_root_dir}/group_vars/all.yml"
}

resource "local_file" "connect_script" {
  sensitive_content = templatefile("${local.playbooks_template_dir}/connect.tmpl",
    {
      jumpbox-pip       = local.allow_public_ip ? azurerm_public_ip.jumpbox-pip[0].ip_address :  azurerm_network_interface.jumpbox-nic.private_ip_address
      jumpbox-user      = azurerm_linux_virtual_machine.jumpbox.admin_username,
      jumpbox-ssh-port  = local.jumpbox_ssh_port
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

resource "local_file" "packer_pip" {
  content = templatefile("${local.packer_root_dir}/templates/options.json.tmpl",
    {
      subscription_id = data.azurerm_subscription.primary.subscription_id
      resource_group  = local.resource_group
      location        = local.location
      sig_name        = azurerm_shared_image_gallery.sig.name
      private_virtual_network_with_public_ip = false # Never use public IPs for packer VMs
      virtual_network_name                   = local.create_vnet ? azurerm_virtual_network.azhop[0].name : data.azurerm_virtual_network.azhop[0].name
      virtual_network_subnet_name            = local.create_admin_subnet ? azurerm_subnet.compute[0].name : data.azurerm_subnet.compute[0].name
      virtual_network_resource_group_name    = local.create_vnet ? azurerm_virtual_network.azhop[0].resource_group_name : data.azurerm_virtual_network.azhop[0].resource_group_name
      ssh_bastion_host = local.allow_public_ip ? azurerm_public_ip.jumpbox-pip[0].ip_address :  azurerm_network_interface.jumpbox-nic.private_ip_address
      ssh_bastion_port = local.jumpbox_ssh_port
      ssh_bastion_username = azurerm_linux_virtual_machine.jumpbox.admin_username
      ssh_bastion_private_key_file = local_file.private_key.filename
    }
  )
  filename = "${local.packer_root_dir}/options.json"
}

# No longer needed as we use the jumpbox as an SSH bastion
# resource "local_file" "packer_nopip" {
#   content = templatefile("${local.packer_root_dir}/templates/options_nopip.json.tmpl",
#     {
#       subscription_id = data.azurerm_subscription.primary.subscription_id
#       resource_group  = local.resource_group
#       location        = local.location
#       sig_name        = azurerm_shared_image_gallery.sig.name
#       private_virtual_network_with_public_ip = local.allow_public_ip
#       virtual_network_name                   = local.create_vnet ? azurerm_virtual_network.azhop[0].name : data.azurerm_virtual_network.azhop[0].name
#       virtual_network_subnet_name            = local.create_admin_subnet ? azurerm_subnet.admin[0].name : data.azurerm_subnet.admin[0].name
#       virtual_network_resource_group_name    = local.create_vnet ? azurerm_virtual_network.azhop[0].resource_group_name : data.azurerm_virtual_network.azhop[0].resource_group_name
#     }
#   )
#   filename = "${local.packer_root_dir}/options_nopip.json"
# }

resource "local_file" "ci_jumpbox" {
  sensitive_content = templatefile("${local.playbooks_template_dir}/jumpbox_ci.tmpl",
    {
      jumpbox-ssh-port  = local.jumpbox_ssh_port
    }
  )
  filename = "${path.root}/cloud-init/jumpbox.yml"
}

data "local_file" "ci_jumpbox" {
  filename = "${path.root}/cloud-init/jumpbox.yml"
  depends_on = [local_file.ci_jumpbox]
}
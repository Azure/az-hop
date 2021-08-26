locals {
    # config files and directories
    packer_root_dir = "${path.cwd}/packer"
    playbook_root_dir = "${path.cwd}/playbooks"
    playbooks_template_dir = "${path.root}/templates"
    configuration_file="${path.cwd}/config.yml"
    configuration_yml=yamldecode(file(local.configuration_file))
    
    # Load parameters from the configuration file
    location = local.configuration_yml["location"]
    resource_group = local.configuration_yml["resource_group"]
    # Create the RG if creating a VNET or when reusing a VNET in another resource group
    create_rg = local.create_vnet || try(split("/", local.vnet_id)[4], local.resource_group) != local.resource_group

    # ANF
    homefs_size_tb = try(local.configuration_yml["homefs_size_tb"], 4)
    homefs_service_level = try(local.configuration_yml["homefs_service_level"], "Standard")
    anf_dual_protocol = try(local.configuration_yml["dual_protocol"], false)
    homedir_mountpoint = try(local.configuration_yml["homedir_mountpoint"], "/anfhome")

    admin_username = local.configuration_yml["admin_user"]
    key_vault_readers = try(local.configuration_yml["key_vault_readers"], null)

    # Lustre
    lustre_archive_account = try(local.configuration_yml["lustre"]["hsm"]["storage_account"], null)
    lustre_rbh_sku = try(local.configuration_yml["lustre"]["rhb_sku"], "Standard_D8d_v4")
    lustre_mds_sku = try(local.configuration_yml["lustre"]["mds_sku"], "Standard_D8d_v4")
    lustre_oss_sku = try(local.configuration_yml["lustre"]["oss_sku"], "Standard_D32d_v4")
    lustre_oss_count = try(local.configuration_yml["lustre"]["oss_count"], 2)

    # VNET
    create_vnet = try(length(local.vnet_id) > 0 ? false : true, true)
    vnet_id = try(local.configuration_yml["network"]["vnet"]["id"], null)

    # VNET Peering
    create_peering = try(length(local.peering_vnet_name) > 0 ? 1 : 0, 0)
    peering_vnet_name = try(local.configuration_yml["network"]["peering"]["vnet_name"], null)
    peering_vnet_resource_group = try(local.configuration_yml["network"]["peering"]["vnet_resource_group"], null)

    # Lockdown scenario
    locked_down_network = try(local.configuration_yml["locked_down_network"]["enforce"], false)
    grant_access_from   = try(local.configuration_yml["locked_down_network"]["grant_access_from"], [])
}
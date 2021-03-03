locals {
    packer_root_dir = "${path.root}/../packer"
    playbook_root_dir = "${path.root}/../playbooks"
    playbooks_template_dir = "${path.root}/templates"
    configuration_file="${path.root}/../config.yml"
    configuration_yml=yamldecode(file(local.configuration_file))
    
    location = local.configuration_yml["location"]
    resource_group = local.configuration_yml["resource_group"]
    homefs_size_tb = local.configuration_yml["homefs_size_tb"]
    admin_username = local.configuration_yml["admin_user"]
    homedir_mountpoint = local.configuration_yml["homedir_mountpoint"]
    key_vault_readers = try(local.configuration_yml["key_vault_readers"], null)
}
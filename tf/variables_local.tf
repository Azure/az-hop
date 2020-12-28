locals {
    packer_root_dir = "${path.root}/../packer"
    playbook_root_dir = "${path.root}/../playbooks"
    playbooks_template_dir = "${local.playbook_root_dir}/templates"
    configuration_file="${path.root}/../deployhpc.yml"
    configuration_yml=yamldecode(file(local.configuration_file))
    
    location = local.configuration_yml["location"]
    resource_group = local.configuration_yml["resource_group"]
    homefs_size_tb = local.configuration_yml["homefs_size_tb"]
    admin_username = local.configuration_yml["admin_user"]
    homedir_mountpoint = local.configuration_yml["homedir_mountpoint"]
}
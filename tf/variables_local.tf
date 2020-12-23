locals {
    configuration_file="${path.root}/../deployhpc.yml"
    configuration_yml=yamldecode(file(local.configuration_file))
    
    location = local.configuration_yml["location"]
    resource_group = local.configuration_yml["resource_group"]
    homefs_size_tb = local.configuration_yml["homefs_size_tb"]
    admin_username = local.configuration_yml["admin_user"]
}
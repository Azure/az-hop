locals {
    location = yamldecode(file("deployhpc.yml"))["location"]
    resource_group = yamldecode(file("deployhpc.yml"))["resource_group"]
    homefs_size = yamldecode(file("deployhpc.yml"))["homefs_size"]
    admin_username = "hpcadmin"
}
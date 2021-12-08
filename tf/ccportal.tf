resource "azurerm_network_interface" "ccportal-nic" {
  name                = "ccportal-nic"
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.create_admin_subnet ? azurerm_subnet.admin[0].id : data.azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "ccportal" {
  name                  = "ccportal"
  location              = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name   = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  vm_size               = try(local.configuration_yml["cyclecloud"].vm_size, "Standard_D2s_v3")
  network_interface_ids = [
    azurerm_network_interface.ccportal-nic.id,
  ]

  os_profile {
    computer_name  = "ccportal"
    admin_username = local.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${local.admin_username}/.ssh/authorized_keys"
      key_data = tls_private_key.internal.public_key_openssh
    }
  }

  storage_os_disk {
    name              = "ccportal-osdisk"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = try(local.configuration_yml["cyclecloud"].image.publisher,"azurecyclecloud")
    offer     = try(local.configuration_yml["cyclecloud"].image.offer, "azure-cyclecloud")
    sku       = try(local.configuration_yml["cyclecloud"].image.sku, "cyclecloud8")
    version   = try(local.configuration_yml["cyclecloud"].image.version, "8.2.120211111")
  }

  plan {
    name      = try(local.configuration_yml["cyclecloud"].plan.name, "cyclecloud8")
    publisher = try(local.configuration_yml["cyclecloud"].plan.publisher, "azurecyclecloud")
    product   = try(local.configuration_yml["cyclecloud"].plan.product, "azure-cyclecloud")
  }

  storage_data_disk {
    lun               = 0
    name              = "ccportal-datadisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 128
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.ccportal.id ]
  }

  #depends_on = [azurerm_network_interface_application_security_group_association.ccportal-asg-asso]
}

data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}

resource "azurerm_user_assigned_identity" "ccportal" {
  location            = local.create_rg ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = local.create_rg ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  name = "ccportal"
}

# resource "random_uuid" "role" {
# }


# resource "azurerm_role_definition" "cyclecloud" {
#   role_definition_id = random_uuid.role.result
#   name               = "CycleCloud-${random_string.resource_postfix.result}"
#   description        = "CycleCloud Orchestrator Role"
#   scope              = data.azurerm_subscription.primary.id

#   permissions {
#     actions     = [ "Microsoft.Commerce/RateCard/read",
#                     "Microsoft.Compute/*/read",
#                     "Microsoft.Compute/availabilitySets/*",
#                     "Microsoft.Compute/disks/*",
#                     "Microsoft.Compute/images/read",
#                     "Microsoft.Compute/locations/usages/read",
#                     "Microsoft.Compute/register/action",
#                     "Microsoft.Compute/skus/read",
#                     "Microsoft.Compute/virtualMachines/*",
#                     "Microsoft.Compute/virtualMachineScaleSets/*",
#                     "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/*",
#                     "Microsoft.ManagedIdentity/userAssignedIdentities/*/assign/action",
#                     "Microsoft.Network/*/read",
#                     "Microsoft.Network/locations/*/read",
#                     "Microsoft.Network/networkInterfaces/read",
#                     "Microsoft.Network/networkInterfaces/write",
#                     "Microsoft.Network/networkInterfaces/delete",
#                     "Microsoft.Network/networkInterfaces/join/action",
#                     "Microsoft.Network/networkSecurityGroups/read",
#                     "Microsoft.Network/networkSecurityGroups/write",
#                     "Microsoft.Network/networkSecurityGroups/delete",
#                     "Microsoft.Network/networkSecurityGroups/join/action",
#                     "Microsoft.Network/publicIPAddresses/read",
#                     "Microsoft.Network/publicIPAddresses/write",
#                     "Microsoft.Network/publicIPAddresses/delete",
#                     "Microsoft.Network/publicIPAddresses/join/action",
#                     "Microsoft.Network/register/action",
#                     "Microsoft.Network/virtualNetworks/read",
#                     "Microsoft.Network/virtualNetworks/subnets/read",
#                     "Microsoft.Network/virtualNetworks/subnets/join/action",
#                     "Microsoft.Resources/deployments/read",
#                     "Microsoft.Resources/subscriptions/resourceGroups/read",
#                     "Microsoft.Resources/subscriptions/resourceGroups/resources/read",
#                     "Microsoft.Resources/subscriptions/operationresults/read",
#                     "Microsoft.Storage/*/read",
#                     "Microsoft.Storage/checknameavailability/read",
#                     "Microsoft.Storage/register/action",
#                     "Microsoft.Storage/storageAccounts/read",
#                     "Microsoft.Storage/storageAccounts/listKeys/action",
#                     "Microsoft.Storage/storageAccounts/write"]
#     not_actions = []
#   }
# }

# Grant Contributor access to Cycle in the az-hop resource group
resource "azurerm_role_assignment" "ccportal_rg" {
  name               = azurerm_user_assigned_identity.ccportal.principal_id
  scope              = local.create_rg ? azurerm_resource_group.rg[0].id : data.azurerm_resource_group.rg[0].id
  role_definition_id = "${data.azurerm_subscription.primary.id}${data.azurerm_role_definition.contributor.id}"
  principal_id       = azurerm_user_assigned_identity.ccportal.principal_id
}

resource "azurerm_network_interface_application_security_group_association" "ccportal-asg-asso" {
  for_each = toset(local.asg_associations["ccportal"])
  network_interface_id          = azurerm_network_interface.ccportal-nic.id
  application_security_group_id = local.create_nsg ? azurerm_application_security_group.asg[each.key].id : data.azurerm_application_security_group.asg[each.key].id
}

var config = json(loadTextContent('azhopconfig.json'))

var adminUser = config.admin_user
var images = config.images

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminSshKey string

@description('Azure region to use')
param location string = resourceGroup().location

var setupScriptTpl = loadTextContent('cloudconfig.yml')
var setupScript = replace(replace(replace(setupScriptTpl, 'SUBSCRIPTION_ID', subscription().id), 'LOCATION', location), 'RESOURCE_GROUP', resourceGroup().name)

/*
 _   _          _                               _      _
| \ | |   ___  | |_  __      __   ___    _ __  | | __ (_)  _ __     __ _
|  \| |  / _ \ | __| \ \ /\ / /  / _ \  | '__| | |/ / | | | '_ \   / _` |
| |\  | |  __/ | |_   \ V  V /  | (_) | | |    |   <  | | | | | | | (_| |
|_| \_|  \___|  \__|   \_/\_/    \___/  |_|    |_|\_\ |_| |_| |_|  \__, |
                                                                   |___/
*/                                               
var vnet = config.vnet
var subnets = vnet.subnets

resource commonNsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsg-common'
  location: location
  properties: {
    securityRules: [
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnet.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet.cidr
      ]
    }
    subnets: [
      {
        name: subnets.frontend.name
        properties: {
          addressPrefix: subnets.frontend.cidr
          networkSecurityGroup: {
            id: commonNsg.id
          }
        }
      }
      {
        name: subnets.admin.name
        properties: {
          addressPrefix: subnets.admin.cidr
          networkSecurityGroup: {
            id: commonNsg.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
            {
              service: 'Microsoft.Sql'
            }
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: subnets.netapp.name
        properties: {
          addressPrefix: subnets.netapp.cidr
          networkSecurityGroup: {
            id: commonNsg.id
          }
          delegations: [
            {
              name: 'netapp'
              properties: {
                serviceName: 'Microsoft.NetApp/volumes'
              }
            }
          ]
        }
      }
      {
        name: subnets.ad.name
        properties: {
          addressPrefix: subnets.ad.cidr
          networkSecurityGroup: {
            id: commonNsg.id
          }
        }
      }
      {
        name: subnets.compute.name
        properties: {
          addressPrefix: subnets.compute.cidr
          networkSecurityGroup: {
            id: commonNsg.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}

resource frontendSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' existing = {
  parent: virtualNetwork
  name: subnets.frontend.name
}
resource adminSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' existing = {
  parent: virtualNetwork
  name: subnets.admin.name
}

resource netappSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' existing = {
  parent: virtualNetwork
  name: subnets.netapp.name
}

resource adSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' existing = {
  parent: virtualNetwork
  name: subnets.ad.name
}

resource computeSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' existing = {
  parent: virtualNetwork
  name: subnets.compute.name
}
    
resource allNgs 'Microsoft.Network/applicationSecurityGroups@2021-08-01' = [ for asgName in config.asgs: {
  name: asgName
  location: location
}]


/*
__     __  __  __       ____                   _
\ \   / / |  \/  |  _  |  _ \    ___   _ __   | |   ___    _   _    ___   _ __
 \ \ / /  | |\/| | (_) | | | |  / _ \ | '_ \  | |  / _ \  | | | |  / _ \ | '__|
  \ V /   | |  | |  _  | |_| | |  __/ | |_) | | | | (_) | | |_| | |  __/ | |
   \_/    |_|  |_| (_) |____/   \___| | .__/  |_|  \___/   \__, |  \___| |_|
                                      |_|                  |___/
*/

var deployer = config.vms.deployer
resource deployerNic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: deployer.name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${deployer.name}-ipconfig'
        properties: {
          subnet: {
            id: adminSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: deployerPip.id
          }
        }
      }
    ]
  }
}

resource deployerPip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${deployer.name}-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

var deployerContributorId = resourceId('microsoft.authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var deployerUserAccessAdministratorId = resourceId('microsoft.authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
var deployerContributorRa = guid(deployerManagedIdentity.name, deployerContributorId, subscription().id)
var deployerUserAccessAdminitratorRa = guid(deployerManagedIdentity.name, deployerUserAccessAdministratorId, subscription().id)
resource deployerManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${deployer.name}-mi'
  location: location
}
resource deployerManagedIdentityContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: deployerContributorRa
  scope: resourceGroup()
  properties: {
    roleDefinitionId: deployerContributorId
    principalId: deployerManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource managedIdentityUserAccessAdminitrator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: deployerUserAccessAdminitratorRa
  scope: resourceGroup()
  properties: {
    roleDefinitionId: deployerUserAccessAdministratorId
    principalId: deployerManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deployerVm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: deployer.name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${deployerManagedIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: deployer.sku
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: deployer.osdisk
        }
      }
      imageReference: images.ubuntu
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: deployerNic.id
        }
      ]
    }
    osProfile: {
      computerName: deployer.name
      adminUsername: adminUser
      customData: base64(setupScript)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUser}/.ssh/authorized_keys'
              keyData: adminSshKey
            }
          ]
        }
      }
    }
  }
}

/*
__     __  __  __           _                               _
\ \   / / |  \/  |  _      | |  _   _   _ __ ___    _ __   | |__     ___   __  __
 \ \ / /  | |\/| | (_)  _  | | | | | | | '_ ` _ \  | '_ \  | '_ \   / _ \  \ \/ /
  \ V /   | |  | |  _  | |_| | | |_| | | | | | | | | |_) | | |_) | | (_) |  >  <
   \_/    |_|  |_| (_)  \___/   \__,_| |_| |_| |_| | .__/  |_.__/   \___/  /_/\_\
                                                   |_|
*/
var jumpbox = config.vms.jumpbox
resource jumpboxNic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: jumpbox.name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${jumpbox.name}-ipconfig'
        properties: {
          subnet: {
            id: adminSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: jumpboxPip.id
          }
        }
      }
    ]
  }
}

resource jumpboxPip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${jumpbox.name}-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

resource jumpboxVm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: jumpbox.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: jumpbox.sku
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: jumpbox.osdisk
        }
      }
      imageReference: images.linux_base
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpboxNic.id
        }
      ]
    }
    osProfile: {
      computerName: jumpbox.name
      adminUsername: adminUser
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUser}/.ssh/authorized_keys'
              keyData: adminSshKey
            }
          ]
        }
      }
    }
  }
}

var config = json(loadTextContent('azhopconfig.json'))

@description('deploy name')
param deployName string = 'deployer'

@description('deploy VM size')
param deployVmSize string = 'Standard_B2ms'

@description('deploy username')
param deployUsername string

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param deployKey string

@description('Azure region to use')
param location string = resourceGroup().location

var deployNicName = '${deployName}-nic'
var deployOsDiskType = 'Standard_LRS'

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
resource deployNic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: deployNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${deployName}-ipconfig'
        properties: {
          subnet: {
            id: adminSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${deployName}-pip'
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

var contributorId = resourceId('microsoft.authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var userAccessAdministratorId = resourceId('microsoft.authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
var contributorRa = guid(managedIdentity.name, contributorId, subscription().id)
var UserAccessAdminitratorRa = guid(managedIdentity.name, userAccessAdministratorId, subscription().id)
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${deployName}-mi'
  location: location
}
resource managedIdentityContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: contributorRa
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource managedIdentityUserAccessAdminitrator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: UserAccessAdminitratorRa
  scope: resourceGroup()
  properties: {
    roleDefinitionId: userAccessAdministratorId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: deployName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: deployVmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: deployOsDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: deployNic.id
        }
      ]
    }
    osProfile: {
      computerName: deployName
      adminUsername: deployUsername
      customData: base64(setupScript)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${deployUsername}/.ssh/authorized_keys'
              keyData: deployKey
            }
          ]
        }
      }
    }
  }
}

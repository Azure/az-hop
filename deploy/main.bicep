@description('Name of new or existing vnet to which Azure Bastion should be deployed')
param vnetName string = 'hpcvnet'
@description('IP prefix for available addresses in vnet address space')
param vnetIpPrefix string = '10.0.0.0/16'
@description('Admin subnet IP prefix')
param adminSubnetIpPrefix string = '10.0.1.0/24'

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

var adminSubnetName = 'admin'
var deployNicName = '${deployName}-nic'
var deployNsgName = '${deployName}-nsg'
var deployOsDiskType = 'Standard_LRS'

var setupScriptTpl = loadTextContent('cloudconfig.yml')
var setupScript = replace(replace(replace(setupScriptTpl, 'SUBSCRIPTION_ID', subscription().id), 'LOCATION', location), 'RESOURCE_GROUP', resourceGroup().name)

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetIpPrefix
      ]
    }
  }
}

resource adminSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  parent: virtualNetwork
  name: adminSubnetName
  properties: {
    addressPrefix: adminSubnetIpPrefix
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

resource deployNsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: deployNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

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
    networkSecurityGroup: {
      id: deployNsg.id
    }
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
//var readerId = resourceId('microsoft.authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
var userAccessAdministratorId = resourceId('microsoft.authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
var contributorRa = guid(managedIdentity.name, contributorId, subscription().id)
//var subscriptionRa = guid(managedIdentity.name, readerId, subscription().id)
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
//resource managedIdentityReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//  name: subscriptionRa
//  scope: resourceGroup()
//  properties: {
//    roleDefinitionId: readerId
//    principalId: managedIdentity.properties.principalId
//    principalType: 'ServicePrincipal'
//  }
//}
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

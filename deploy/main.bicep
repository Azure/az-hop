@description('Name of new or existing vnet to which Azure Bastion should be deployed')
param vnetName string = 'hpcvnet'

@description('IP prefix for available addresses in vnet address space')
param vnetIpPrefix string = '10.1.0.0/16'

@description('Bastion subnet IP prefix MUST be within vnet IP prefix address space')
param bastionSubnetIpPrefix string = '10.1.4.0/26'

@description('Name of Azure Bastion resource')
param bastionHostName string = 'bastion'

@description('Admin subnet IP prefix')
param adminSubnetIpPrefix string = '10.1.1.0/24'

@description('Jumpbox name')
param jumpboxName string = 'deployer'

@description('Jumpbox VM size')
param jumpboxVmSize string = 'Standard_B2ms'

@description('Jumpbox username')
param jumpboxUsername string

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param jumpboxKey string

@description('Azure region for Bastion and virtual network')
param location string = resourceGroup().location

var publicIpAddressName = '${bastionHostName}-pip'
var bastionSubnetName = 'AzureBastionSubnet'
var adminSubnetName = 'admin'
var jumpboxNicName = '${jumpboxName}-nic'
var jumpboxNsgName = '${jumpboxName}-nsg'
var jumpboxOsDiskType = 'Standard_LRS'

resource publicIp 'Microsoft.Network/publicIpAddresses@2020-05-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetIpPrefix
      ]
    }
    subnets: [
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetIpPrefix
        }
      }
      {
        name: adminSubnetName
        properties: {
          addressPrefix: adminSubnetIpPrefix
        }
      }
    ]
  }
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  parent: virtualNetwork
  name: bastionSubnetName
  properties: {
    addressPrefix: bastionSubnetIpPrefix
  }
}

resource adminSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  parent: virtualNetwork
  name: adminSubnetName
  properties: {
    addressPrefix: adminSubnetIpPrefix
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2020-05-01' = {
  name: bastionHostName
  location: location
  dependsOn: [
    virtualNetwork
  ]
  properties: {
    ipConfigurations: [
      {
        name: '${bastionHostName}-ipconfig'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource jumpboxNsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: jumpboxNsgName
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

resource jumpboxNic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: jumpboxNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${jumpboxName}-ipconfig'
        properties: {
          subnet: {
            id: adminSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: jumpboxNsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: jumpboxName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: jumpboxVmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: jumpboxOsDiskType
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
          id: jumpboxNic.id
        }
      ]
    }
    osProfile: {
      computerName: jumpboxName
      adminUsername: jumpboxUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${jumpboxUsername}/.ssh/authorized_keys'
              keyData: jumpboxKey
            }
          ]
        }
      }
    }
  }
}

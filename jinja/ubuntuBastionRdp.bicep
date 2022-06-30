
@description('Azure region to use')
param location string = resourceGroup().location

@description('Admin username for the Virtual Machine.')
param adminUser string

@description('Admin password for the Virtual Machine.')
@secure()
param adminPassword string

var ubuntuInstallScript = '''
#!/bin/bash

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install ubuntu-desktop
apt-get -y install xrdp
systemctl enable xrdp
systemctl start xrdp

'''

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: 'vnet'
  tags: {
    NRMSBastion: ''
  }
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.201.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'main'
        properties: {
          addressPrefix: '10.201.1.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.201.0.0/24'
        }
      }
    ]
  }
}

resource mainSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' existing = {
  parent: virtualNetwork
  name: 'main'
}
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' existing = {
  parent: virtualNetwork
  name: 'AzureBastionSubnet'
}

resource ubuntuNic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: 'ubuntu-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'lustre-ipconfig'
        properties: {
          subnet: {
            id: mainSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource ubuntuVm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: 'ubuntu'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D8d_v4'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        caching: 'ReadWrite'
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
          id: ubuntuNic.id
        }
      ]
    }
    osProfile: {
      computerName: 'ubuntu'
      adminUsername: adminUser
      adminPassword: adminPassword
      customData: base64(ubuntuInstallScript)
    }
  }
}

resource bastionPip 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: 'bastion-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-08-01' = {
  name: 'bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

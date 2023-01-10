targetScope = 'resourceGroup'

param name string
param vm object
param image object
param location string = resourceGroup().location
param resourcePostfix string = '${uniqueString(subscription().subscriptionId, resourceGroup().id)}x'
param subnetId string
param adminUser string
@secure()
param secrets object

var role_lookup = {
  Contributor: resourceId('microsoft.authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  UserAccessAdministrator: resourceId('microsoft.authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
}

var requires_identity = contains(vm, 'identity')

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = if (requires_identity) {
  name: '${name}-mi'
  location: location
}

output principalId string = requires_identity ? managedIdentity.properties.principalId : ''

var roles = requires_identity && contains(vm.identity, 'roles') ? vm.identity.roles : []

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [ for role in roles: {
  name: guid(name, role, resourceGroup().id, subscription().id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: role_lookup[role]
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}]

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-05-01' = if (contains(vm, 'pip') && vm.pip) {
  name: '${name}-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel : '${name}${resourcePostfix}'
    }
  }
}

var count = contains(vm, 'count') && vm.count > 1 ? vm.count : 1
var vmPrefixes = [ for i in range(0, count): count > 1 ? '-${(i + 1)}' : '' ]

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = [ for vmPrefix in vmPrefixes: {
  name: '${name}${vmPrefix}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${name}${vmPrefix}-ipconfig'
        properties: union(
          {
            subnet: {
              id: subnetId
            }
            privateIPAllocationMethod: 'Dynamic'
          }, contains(vm, 'pip') && vm.pip ? {
            id: publicIp.id
          } : {}
        )
      }
    ]
  }
}]

var datadisks = contains(vm, 'datadisks') ? vm.datadisks : []

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = [ for (vmPrefix, i) in vmPrefixes: {
  name: '${name}${vmPrefix}'
  location: location
  plan: contains(image, 'plan') && image.plan == true ? {
    publisher: image.ref.publisher
    product: image.ref.offer
    name: image.ref.sku
  } : null
  identity: requires_identity ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  } : null
  properties: {
    hardwareProfile: {
      vmSize: vm.sku
    }
    storageProfile: {
      dataDisks: [ for (disk, idx) in datadisks: union({
        name: disk.name
        managedDisk: {
          storageAccountType: disk.disksku
        }
        diskSizeGB: disk.size
        lun: idx
        createOption: 'Empty'
      }, contains(disk, 'caching') ? {
        caching: disk.caching
      } : {}
      )]
      osDisk: union(
        {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: vm.osdisksku
          }
          caching: 'ReadWrite'
        }, contains(vm, 'osdisksize') ? {
          diskSizeGB: vm.osdisksize
        } : {}
      )
      imageReference: image.ref
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
    osProfile: union(
      {
        computerName: '${name}${vmPrefix}'
        adminUsername: adminUser      
      }, contains(vm, 'deploy_script') ? { // deploy script
        customData: base64(vm.deploy_script)
      } : {}, contains(vm, 'windows') && vm.windows == true ? { // windows
        adminPassword: secrets.adminPassword
        windowsConfiguration: {
          winRM: {
            listeners: [
              {
                protocol: 'Http'
              }
            ]
          }
        }
      } : {}, ! contains(vm, 'windows') || vm.windows == false ? { // linux
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUser}/.ssh/authorized_keys'
                keyData: secrets.adminSshPublicKey
              }
            ]
          }
        }
      } : {}, contains(vm, 'ahub') && vm.ahub == true ? { // ahub
        licenseType: 'Windows_Server'
      } : {}
    )
  }
}]

//output private_ip string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output fqdn string = contains(vm, 'pip') && vm.pip ? publicIp.properties.dnsSettings.fqdn : ''
output privateIps array = [ for i in range(0, count): nic[i].properties.ipConfigurations[0].properties.privateIPAddress ]

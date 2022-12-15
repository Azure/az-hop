targetScope = 'resourceGroup'

param config object
/*
deployer:
  run_deploy_script: true
  subnet_id: frontend
  sku: Standard_B2ms
  osdisksku: StandardSSD_LRS
  image: ubuntu
  pip: true
  plan:
    publisher:
    product:
    name:
  datadisks:
    name:
    disksku:
    size:
    caching
  identity:
    keyvault:
      key_permissions: [ All ]
      secret_permissions: [ All ]
    roles:
      - b24988ac-6180-42a0-ab88-20f7382dd24c # Contributor
      - 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9 # User Access Administrator
  asgs: [ asg-ssh, asg-jumpbox, asg-deployer, asg-ad-client, asg-telegraf, asg-nfs-client ]
*/
param location string = resourceGroup().location
param resourcePostfix string = '${uniqueString(subscription().subscriptionId, resourceGroup().id)}x'

var role_lookup = {
  Contributor: resourceId('microsoft.authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  UserAccessAdministrator: resourceId('microsoft.authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
}

var requires_identity = contains(config, 'identity')

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = if (requires_identity) {
  name: '${config.name}-mi'
  location: location
}

output principalId string = managedIdentity.properties.principalId

var roles = requires_identity ? config.identity.roles : []

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = [ for role in roles: {
  name: guid(config.name, role, resourceGroup().id, subscription().id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: role_lookup[role]
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}]

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-05-01' = if (config.pip) {
  name: '${config.name}-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel : '${config.name}${resourcePostfix}'
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: '${config.name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${config.name}-ipconfig'
        properties: {
          subnet: {
            id: config.subnet_id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: (config.pip) ? {
            id: publicIp.id
          } : {}
        }
      }
    ]
  }
}

var datadisks = contains(config, 'datadisks') ? config.datadisks : []

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: config.name
  location: location
  plan: contains(config, 'plan') ? {
    publisher: config.plan.publisher
    product: config.plan.product
    name: config.plan.name
  } : null
  identity: requires_identity ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  } : null
  properties: {
    hardwareProfile: {
      vmSize: config.sku
    }
    storageProfile: {
      dataDisks: [ for (disk, idx) in config.datadisks: union({
        name: disk.name
        managedDisk: {
          storageAccountType: disk.disksku
        }
        diskSizeGB: disk.size
        lun: idx
        createOption: 'Empty'
      }, disk.caching ? {
        caching: disk.caching
      } : {}
      )]
      osDisk: union({
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: config.osdisksku
        }
        caching: 'ReadWrite'
      }, contains(config, 'osdisksize') ? {
        diskSizeGB: config.osdisksize
      } : {}
      )
      imageReference: {
        publisher: config.image.publisher
        offer: config.image.offer
        sku: config.image.sku
        version: config.image.version
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: config.name
      
    }
  }
}

output private_ip string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output fqdn string = config.pip ? publicIp.properties.dnsSettings.fqdn : ''

targetScope = 'resourceGroup'

param location string
param mariaDbName string
param adminUser string
@secure()
param adminPassword string
param adminSubnetId string

param sslEnforcement bool
param vnetId string

resource mariaDb 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: mariaDbName
  location: location
  
  sku: {
    name: 'GP_Gen5_2'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    sslEnforcement: sslEnforcement ? 'Enabled' : 'Disabled'
    storageProfile: {
      backupRetentionDays: 35
      geoRedundantBackup: 'Disabled'
      storageAutogrow: 'Enabled'
      storageMB: 5120
    }
    version: '10.3'
    createMode: 'Default'
    administratorLogin: adminUser
    administratorLoginPassword: adminPassword
  }
}

output mariaDb_fqdn string = reference(mariaDb.id, mariaDb.apiVersion, 'full').properties.fullyQualifiedDomainName

resource mariaDbPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: '${mariaDbName}-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${mariaDbName}-private-connection'
        properties: {
          privateLinkServiceId: mariaDb.id
          groupIds: [
            'mariadbServer'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    subnet: {
      id: adminSubnetId
    }
  }
}

var mariaDbEndpointLookup = {
  AzureCloud: '.mariadb.database.azure.com'
  AzureUSGovernment: '.mariadb.database.usgovcloudapi.net'
  AzureGermanCloud: '.mariadb.database.cloudapi.de'
  AzureChinaCloud: '.mariadb.database.chinacloudapi.cn'
}

var mariaDbPrivateLinkName =  'privatelink${mariaDbEndpointLookup[environment().name]}'

resource mariaDbPrivateDnsZone 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  parent: mariaDbPrivateEndpoint
  name: 'private-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: mariaDbPrivateLinkName

        properties: {
          privateDnsZoneId: privateDnsZones_global.id
        }
      }
    ]
  }
}

resource privateDnsZones_global 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: mariaDbPrivateLinkName
  location: 'global'
}

resource privateDnsZones_az_hop_private 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZones_global
  name: 'az-hop-private'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

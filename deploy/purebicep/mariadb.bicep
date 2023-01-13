targetScope = 'resourceGroup'

param location string = resourceGroup().location
param resourcePostfix string
param adminUser string
@secure()
param adminPassword string
param adminSubnetId string
param frontendSubnetId string

param sslEnforcement bool
param vnetId string

resource mariaDb 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: 'azhop-${resourcePostfix}'
  location: location
  
  sku: {
    name: 'GP_Gen5_2'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    sslEnforcement: sslEnforcement ? 'Enabled' : 'Disabled'
    storageProfile: {
      backupRetentionDays: 21
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
/*
resource mariaDbAdmin 'Microsoft.DBforMariaDB/servers/virtualNetworkRules@2018-06-01' = {
  name: 'AllowAccessAdmin'
  parent: mariaDb
  properties: {
    virtualNetworkSubnetId: adminSubnetId
  }
}

resource mariaDbFrontend 'Microsoft.DBforMariaDB/servers/virtualNetworkRules@2018-06-01' = {
  name: 'AllowAccessFrontend'
  parent: mariaDb
  properties: {
    virtualNetworkSubnetId: frontendSubnetId
  }
}
*/
output mariaDb_fqdn string = reference(mariaDb.id, mariaDb.apiVersion, 'full').properties.fullyQualifiedDomainName

resource mariaDbPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: 'mariadb-pe-${resourcePostfix}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'mariadb-private-connection-${resourcePostfix}'
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

var mariaDbPrivateLinkName = 'privatelink.mariadb.database.azure.com'

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

resource privateDnsZones_global 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: mariaDbPrivateLinkName
  location: 'global'
}

resource privateDnsZones_az_hop_private 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
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

targetScope = 'resourceGroup'

param location string = resourceGroup().location
param resourcePostfix string
param adminUser string
@secure()
param adminPassword string
param adminSubnetId string
param frontendSubnetId string

resource mysql 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: 'azhop-${resourcePostfix}'
  location: location
  
  sku: {
    name: 'GP_Gen5_2'
  }
  properties: {
    minimalTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    sslEnforcement: 'Enabled'
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

resource mysqlAdmin 'Microsoft.DBforMariaDB/servers/virtualNetworkRules@2018-06-01' = {
  name: 'AllowAccessAdmin'
  parent: mysql
  properties: {
    virtualNetworkSubnetId: adminSubnetId
  }
}

resource mysqlFrontend 'Microsoft.DBforMariaDB/servers/virtualNetworkRules@2018-06-01' = {
  name: 'AllowAccessFrontend'
  parent: mysql
  properties: {
    virtualNetworkSubnetId: frontendSubnetId
  }
}

output mysql_fqdn string = reference(mysql.id, mysql.apiVersion, 'full').properties.fullyQualifiedDomainName

targetScope = 'resourceGroup'

param location string
param saName string
param lockDownNetwork bool
param allowableIps array
param subnetIds array

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: saName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: union(
    {
      accessTier: 'Hot'
      minimumTlsVersion: 'TLS1_2'
    },
    lockDownNetwork ? {
      networkAcls: {
        defaultAction: 'Deny'
        ipRules: [
          map(allowableIps, ip => { value: ip })
        ]
        virtualNetworkRules: [
          map(subnetIds, id => { id: id })
        ]
      }
    } : {}
  )
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource lustreArchive 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: 'lustre'
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}

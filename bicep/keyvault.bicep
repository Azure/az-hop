targetScope = 'resourceGroup'

param location string
param kvName string
param subnetId string
param keyvaultReaderOids array
param keyvaultOwnerId string
param lockDownNetwork bool
param allowableIps array

// Use the output so that the keyvault name can be used in other modules as a dependency
output keyvaultName string = kvName

resource kv 'Microsoft.KeyVault/vaults@2022-11-01' = {
  name: kvName
  location: location
  properties: {
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    softDeleteRetentionInDays: 7
    enableSoftDelete: true
    enablePurgeProtection: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: lockDownNetwork ? 'Deny' : 'Allow'
      ipRules: map(allowableIps, ip => { value: ip })
      virtualNetworkRules: [
        {
          id: subnetId
        }
      ]
    }
    accessPolicies: union(
      map(keyvaultReaderOids, oid => {
        objectId: oid
        permissions: {
          secrets: [
            'Get'
            'List'
          ]
        }
        tenantId: subscription().tenantId
      }),
      keyvaultOwnerId != '' ? [{
        objectId: keyvaultOwnerId
        permissions: {
          secrets: ['All']
        }
        tenantId: subscription().tenantId
      }] : []
    )
  }
}

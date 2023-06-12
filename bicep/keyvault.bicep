targetScope = 'resourceGroup'

param location string
param kvName string
param subnetId string
param keyvaultReaderOids array
param keyvaultOwnerId string
param lockDownNetwork bool
param allowableIps array
param identityPerms array

output keyvaultName string = kvName

resource kv 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: kvName
  location: location
  properties: {
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    softDeleteRetentionInDays: 7
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
      map(
        filter(
          identityPerms,
          id => (contains(id, 'key_permissions') && !empty(id.key_permissions)) || (contains(id, 'secret_permissions') && !empty(id.secret_permissions))
        ),
        id => {
        objectId: id.principalId
        permissions: {
          keys: contains(id, 'key_permissions') ? id.key_permissions : []
          secrets: contains(id, 'secret_permissions') ? id.secret_permissions : []
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

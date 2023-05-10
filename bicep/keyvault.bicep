targetScope = 'resourceGroup'

param location string
param resourcePostfix string
param subnetId string
param keyvaultReaderOids array
param keyvaultOwnerId string
param lockDownNetwork bool
param allowableIps array
param identityPerms array

var kvName = 'kv${resourcePostfix}'

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
          id => !empty(id.key_permissions) || !empty(id.secret_permissions)
        ),
        id => {
        objectId: id.principalId
        permissions: {
          keys: id.key_permissions
          secrets: id.secret_permissions
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

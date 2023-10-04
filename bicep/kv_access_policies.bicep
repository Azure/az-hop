targetScope = 'resourceGroup'
param vaultName string
param principalId string
param secret_permissions array

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: vaultName
}
resource kvSecret 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'add'
  parent: kv
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: principalId
        permissions: {
          secrets: secret_permissions
        }
      }
    ]
  }
}

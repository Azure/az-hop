targetScope = 'resourceGroup'
param vaultName string
param name string
@secure()
param value string

resource kv 'Microsoft.KeyVault/vaults@2022-11-01' existing = {
  name: vaultName
}
resource kvSecret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  name: name
  parent: kv
  properties: {
    value: value
  }
}

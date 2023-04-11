targetScope = 'resourceGroup'

param name string
param roles array
param principalId string

var role_lookup = {
  Contributor: resourceId('microsoft.authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  UserAccessAdministrator: resourceId('microsoft.authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
}

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [ for role in roles: {
  name: guid(name, role, resourceGroup().id, subscription().id)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: role_lookup[role]
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]


targetScope = 'subscription'

@description('Azure region to use')
param location string = deployment().location

@description('Identity of the deployer if not deploying from a deployer VM')
param loggedUserObjectId string = ''

@description('Branch of the azhop repo to pull - Default to main')
param branchName string = 'main'

@description('Autogenerate passwords and SSH key pair.')
param autogenerateSecrets bool = false

@description('SSH Public Key for the Virtual Machines.')
@secure()
param adminSshPublicKey string = ''

@description('SSH Private Key for the Virtual Machines.')
@secure()
param adminSshPrivateKey string = ''

@description('The Windows/Active Directory password.')
@secure()
param adminPassword string = ''

@description('Password for the database admin user')
// todo: change to database admin password
@secure()
param databaseAdminPassword string = ''

@description('Input configuration file in json format')
param azhopConfig object

var resource_group_name = azhopConfig.resource_group

resource azhopResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resource_group_name
  location: location
  tags: contains(azhopConfig, 'tags') ? azhopConfig.tags : {}
}

module azhopDeployment './azhop.bicep' = {
  name: 'azhop'
  scope: azhopResourceGroup
  params: {
    location: location
    autogenerateSecrets: autogenerateSecrets
    adminSshPublicKey: adminSshPublicKey
    adminSshPrivateKey: adminSshPrivateKey
    adminPassword: adminPassword
    databaseAdminPassword: databaseAdminPassword
    loggedUserObjectId: loggedUserObjectId
    branchName: branchName
    azhopConfig: azhopConfig
  }
}

var vnetPeerings = contains(azhopConfig.network, 'peering') ? azhopConfig.network.peering : []
module azhopPeerings './vnetpeering.bicep' = [ for peer in vnetPeerings: {
  name: 'peer_from${peer.vnet_name}'
  scope: resourceGroup(peer.vnet_resource_group)
  params: {
    name: '${azhopConfig.resource_group}_${azhopConfig.network.vnet.name}'
    vnetName: peer.vnet_name
    allowGateway: contains(peer, 'vnet_allow_gateway') ? peer.vnet_allow_gateway : true
    vnetId: azhopDeployment.outputs.vnetId
  }
}]

var subscriptionReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(azhopResourceGroup.id, subscriptionReaderRoleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionReaderRoleDefinitionId
    principalId: azhopDeployment.outputs.ccportalPrincipalId
    principalType: 'ServicePrincipal'
  }
}

targetScope = 'resourceGroup'

@description('VNet name to peer to')
param vnetName string

@description('VNet Resource group name to peer to')
param vnetResourceGroup string

@description('allow gateway transit (default: true)')
param allowGateway bool = true

@description('VNET Id of the azhop VNET')
param vnetId string

// peering to our vnet. The peering to remote vnet is built into the subnet module
resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${vnetResourceGroup}-${vnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGateway
    remoteVirtualNetwork: {
      id: vnetId
    }
  }
}


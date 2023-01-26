targetScope = 'resourceGroup'

@description('Peer name')
param name string

@description('VNet name to peer to')
param vnetName string

@description('allow gateway transit (default: true)')
param allowGateway bool = true

@description('VNET Id of the azhop VNET')
param vnetId string

resource peeredVirtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' existing = { 
  name: vnetName
}

// peering to our vnet. The peering to remote vnet is built into the subnet module
resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: name
  parent: peeredVirtualNetwork
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGateway
    remoteVirtualNetwork: {
      id: vnetId
    }
  }
}

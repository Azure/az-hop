targetScope = 'resourceGroup'

@description('VNet name to peer to')
param vnetName string

@description('Resource Group of the VNet to peer to')
param vnetRGName string

@description('allow gateway transit (default: true)')
param allowGateway bool = true

@description('VNET Id of the azhop VNET')
param vnetId string

resource azhop_to_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${vnetRGName}-${vnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: allowGateway
    remoteVirtualNetwork: {
      id: resourceId(vnetRGName, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
}

resource peer_to_azhop 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${resourceGroup().name}-${vnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGateway
    remoteVirtualNetwork: {
      id: vnetId
    }
  }
}


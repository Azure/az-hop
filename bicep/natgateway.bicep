targetScope = 'resourceGroup'

param location string
param name string


resource publicip 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: 'pip-${name}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource natgateway 'Microsoft.Network/natGateways@2023-06-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicip.id
      }
    ]
  }
}

output NATGatewayId string = natgateway.id

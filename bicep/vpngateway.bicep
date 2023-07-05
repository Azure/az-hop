targetScope = 'resourceGroup'

param location string
param subnetId string

var audienceMap = {
  AzureCloud: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
  AzureUSGovernment: '51bb15d4-3a4f-4ebf-9dca-40096fe32426'
  AzureGermanCloud: '538ee9e6-310a-468d-afef-ea97365856a9'
  AzureChinaCloud: '49f817b6-84ae-4cc0-928c-73f27289b3aa'
}

var tenantId = subscription().tenantId
var cloud = environment().name
var audience = audienceMap[cloud]
var tenant = uri(environment().authentication.loginEndpoint, tenantId)
var issuer = 'https://sts.windows.net/${tenantId}/'

var vpnClientAddressPool = '172.16.0.0/24'

resource vpnGatewayPip 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'vpngateway-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2022-07-01' = {
  name: 'vpngateway'
  location: location
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'vpngateway-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vpnGatewayPip.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnClientConfiguration: {
      aadAudience: audience
      aadIssuer: issuer
      aadTenant: tenant

      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPool
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
    }
  }
}

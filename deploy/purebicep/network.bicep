targetScope = 'resourceGroup'

param location string = resourceGroup().location
param deployGateway bool
param deployBastion bool
param deployLustre bool
param publicIp bool
param vnet object
param asgNames array
param servicePorts object
param nsgRules object

var securityRules = [ for rule in items(union(
    nsgRules.default,
    publicIp ? nsgRules.internet : nsgRules.hub,
    deployBastion ? nsgRules.bastion : {},
    deployGateway ? nsgRules.gateway : {},
    deployLustre ? nsgRules.lustre : {}
  )): {
  name: rule.key
  properties: union(
    {
      priority: rule.value[0]
      direction: rule.value[1]
      access: rule.value[2]
      protocol: rule.value[3]
      sourcePortRange: '*'
      destinationPortRanges: servicePorts[rule.value[4]]
    },
    rule.value[5] == 'asg' ? { 
      sourceApplicationSecurityGroups: [{
        id: resourceId('Microsoft.Network/applicationSecurityGroups', rule.value[6])
      }] 
    } : {},
    rule.value[5] == 'tag' ? { sourceAddressPrefix: rule.value[6] } : {},
    rule.value[5] == 'subnet' ? { sourceAddressPrefix: vnet.subnets[rule.value[6]].cidr } : {}, 
    rule.value[7] == 'asg' ? { 
      destinationApplicationSecurityGroups: [{
        id: resourceId('Microsoft.Network/applicationSecurityGroups', rule.value[8])
      }] 
    } : {},
    rule.value[7] == 'tag' ? { destinationAddressPrefix: rule.value[8] } : {},
    rule.value[7] == 'subnet' ? { destinationAddressPrefix: vnet.subnets[rule.value[8]].cidr } : {}
  )
}]

resource asgs 'Microsoft.Network/applicationSecurityGroups@2022-07-01' = [ for name in asgNames: {
  name: name
  location: location
}]

resource commonNsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-common'
  location: location
  properties: {
    securityRules: securityRules
  }
  dependsOn: [
    asgs
  ]
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnet.name
  location: location
  tags: contains(vnet, 'tags') ? vnet.tags : {}
  properties: {
    addressSpace: {
      addressPrefixes: [ vnet.cidr ]
    }
    subnets: [ for subnet in items(vnet.subnets): {
      name: subnet.value.name
      properties: {
        addressPrefix: subnet.value.cidr
        networkSecurityGroup: contains(subnet.value, 'apply_nsg') && subnet.value.apply_nsg == false ? null : {
          id: commonNsg.id
        }
        delegations: contains(subnet.value, 'delegations') ? map(subnet.value.delegations, delegation => {
          name: subnet.value.name
          properties: {
            serviceName: delegation
          }
        }) : []
        serviceEndpoints: contains(subnet.value, 'service_endpoints') ? map(subnet.value.service_endpoints, endpoint => {
          service: endpoint
        }) : []
      }
    }]
  }
}

output subnetIds object = reduce(
  map(
    items(vnet.subnets), 
    subnet => { 
      '${subnet.key}': filter(
        virtualNetwork.properties.subnets, (s) => s.name == subnet.value.name
      )[0].id 
    }
  ), 
  {}, 
  (cur, next) => union(cur, next)
)


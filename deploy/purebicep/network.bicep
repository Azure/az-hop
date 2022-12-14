targetScope = 'resourceGroup'

param location string = resourceGroup().location
param deployGateway bool = true
param deployBastion bool = true
param publicIp bool = false
param vnet object

var asgNames = [ 
  'asg-ssh', 'asg-rdp', 'asg-jumpbox', 'asg-ad', 'asg-ad-client', 'asg-lustre', 'asg-lustre-client'
  'asg-pbs', 'asg-pbs-client', 'asg-cyclecloud', 'asg-cyclecloud-client', 'asg-nfs-client'
  'asg-telegraf', 'asg-grafana', 'asg-robinhood', 'asg-ondemand', 'asg-deployer', 'asg-guacamole'
]

var servicePorts = {
  All: ['0-65535']
  Bastion: ['22', '3389']
  Web: ['443', '80']
  Ssh: ['22']
  Socks: ['5985']
  // DNS, Kerberos, RpcMapper, Ldap, Smb, KerberosPass, LdapSsl, LdapGc, LdapGcSsl, AD Web Services, RpcSam
  DomainControlerTcp: ['53', '88', '135', '389', '445', '464', '636', '3268', '3269', '9389', '49152-65535']
  // DNS, Kerberos, W32Time, NetBIOS, Ldap, KerberosPass, LdapSsl
  DomainControlerUdp: ['53', '88', '123', '138', '389', '464', '636']
  // Web, NoVNC, WebSockify
  NoVnc: ['80', '443', '5900-5910', '61001-61010']
  Dns: ['53']
  Rdp: ['3389']
  Pbs: ['6200', '15001-15009', '17001', '32768-61000', '6817-6819']
  Slurmd: ['6818']
  Lustre: ['635', '988']
  Nfs: ['111', '635', '2049', '4045', '4046']
  SMB: ['445']
  Telegraf: ['8086']
  Grafana: ['3000']
  // HTTPS, AMQP
  CycleCloud: ['9443', '5672']
  MySQL: ['3306', '33060']
  Guacamole: ['8080']
  WinRM: ['5985', '5986']
}

var nsgRules = {
  //
  // INBOUND RULES
  //

  // AD communication
  AllowAdServerTcpIn          : ['220', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad', 'asg', 'asg-ad-client']
  AllowAdServerUdpIn          : ['230', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad', 'asg', 'asg-ad-client']
  AllowAdClientTcpIn          : ['240', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad-client', 'asg', 'asg-ad']
  AllowAdClientUdpIn          : ['250', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad-client', 'asg', 'asg-ad']
  AllowAdServerComputeTcpIn   : ['260', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad', 'subnet', 'compute']
  AllowAdServerComputeUdpIn   : ['270', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad', 'subnet', 'compute']
  AllowAdClientComputeTcpIn   : ['280', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet', 'compute', 'asg', 'asg-ad']
  AllowAdClientComputeUdpIn   : ['290', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet', 'compute', 'asg', 'asg-ad']
  AllowAdServerNetappTcpIn    : ['300', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet', 'netapp', 'asg', 'asg-ad']
  AllowAdServerNetappUdpIn    : ['310', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet', 'netapp', 'asg', 'asg-ad']

  // SSH internal rules
  AllowSshFromJumpboxIn       : ['320', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-jumpbox', 'asg', 'asg-ssh']
  AllowSshFromComputeIn       : ['330', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'subnet', 'compute', 'asg', 'asg-ssh']
  // Only in a deployer VM scenario
  AllowSshFromDeployerIn      : ['340', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-deployer', 'asg', 'asg-ssh'] 
  // Only in a deployer VM scenario
  AllowDeployerToPackerSshIn  : ['350', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-deployer', 'subnet', 'admin']
  AllowSshToComputeIn         : ['360', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-ssh', 'subnet', 'compute']
  AllowSshComputeComputeIn    : ['365', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'subnet', 'compute', 'subnet', 'compute']

  // PBS
  AllowPbsIn                  : ['369', 'Inbound', 'Allow', '*', 'Pbs', 'asg', 'asg-pbs', 'asg', 'asg-pbs-client']
  AllowPbsClientIn            : ['370', 'Inbound', 'Allow', '*', 'Pbs', 'asg', 'asg-pbs-client', 'asg', 'asg-pbs']
  AllowPbsComputeIn           : ['380', 'Inbound', 'Allow', '*', 'Pbs', 'asg', 'asg-pbs', 'subnet', 'compute']
  AllowComputePbsClientIn     : ['390', 'Inbound', 'Allow', '*', 'Pbs', 'subnet', 'compute', 'asg', 'asg-pbs-client']
  AllowComputePbsIn           : ['400', 'Inbound', 'Allow', '*', 'Pbs', 'subnet', 'compute', 'asg', 'asg-pbs']
  AllowComputeComputePbsIn    : ['401', 'Inbound', 'Allow', '*', 'Pbs', 'subnet', 'compute', 'subnet', 'compute']

  // SLURM
  AllowComputeSlurmIn         : ['405', 'Inbound', 'Allow', '*', 'Slurmd', 'asg', 'asg-ondemand', 'subnet', 'compute']

  // Lustre
  AllowLustreIn               : ['409', 'Inbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre', 'asg', 'asg-lustre-client']
  AllowLustreClientIn         : ['410', 'Inbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre-client', 'asg', 'asg-lustre']
  AllowLustreClientComputeIn  : ['420', 'Inbound', 'Allow', 'Tcp', 'Lustre', 'subnet', 'compute', 'asg', 'asg-lustre']
  AllowRobinhoodIn            : ['430', 'Inbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-ondemand', 'asg', 'asg-robinhood']

  // CycleCloud
  AllowCycleWebIn             : ['440', 'Inbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-ondemand', 'asg', 'asg-cyclecloud']
  AllowCycleClientIn          : ['450', 'Inbound', 'Allow', 'Tcp', 'CycleCloud', 'asg', 'asg-cyclecloud-client', 'asg', 'asg-cyclecloud']
  AllowCycleClientComputeIn   : ['460', 'Inbound', 'Allow', 'Tcp', 'CycleCloud', 'subnet', 'compute', 'asg', 'asg-cyclecloud']
  AllowCycleServerIn          : ['465', 'Inbound', 'Allow', 'Tcp', 'CycleCloud', 'asg', 'asg-cyclecloud', 'asg', 'asg-cyclecloud-client']

  // OnDemand NoVNC
  AllowComputeNoVncIn         : ['470', 'Inbound', 'Allow', 'Tcp', 'NoVnc', 'subnet', 'compute', 'asg', 'asg-ondemand']
  AllowNoVncComputeIn         : ['480', 'Inbound', 'Allow', 'Tcp', 'NoVnc', 'asg', 'asg-ondemand', 'subnet', 'compute']

  // Telegraf / Grafana
  AllowTelegrafIn             : ['490', 'Inbound', 'Allow', 'Tcp', 'Telegraf', 'asg', 'asg-telegraf', 'asg', 'asg-grafana']
  AllowComputeTelegrafIn      : ['500', 'Inbound', 'Allow', 'Tcp', 'Telegraf', 'subnet', 'compute', 'asg', 'asg-grafana']
  AllowGrafanaIn              : ['510', 'Inbound', 'Allow', 'Tcp', 'Grafana', 'asg', 'asg-ondemand', 'asg', 'asg-grafana']

  // Admin and Deployment
  AllowWinRMIn                : ['520', 'Inbound', 'Allow', 'Tcp', 'WinRM', 'asg', 'asg-jumpbox', 'asg', 'asg-rdp']
  AllowRdpIn                  : ['550', 'Inbound', 'Allow', 'Tcp', 'Rdp', 'asg', 'asg-jumpbox', 'asg', 'asg-rdp']
  AllowWebDeployerIn          : ['595', 'Inbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-deployer', 'asg', 'asg-ondemand']

  // Guacamole
  AllowGuacamoleRdpIn         : ['610', 'Inbound', 'Allow', 'Tcp', 'Rdp', 'asg', 'asg-guacamole', 'subnet', 'compute']

  // Deny all remaining traffic
  DenyVnetInbound             : ['3100', 'Inbound', 'Deny', '*', 'All', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']


  //
  // Outbound
  //

  // AD communication
  AllowAdClientTcpOut         : ['200', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad-client', 'asg', 'asg-ad']
  AllowAdClientUdpOut         : ['210', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad-client', 'asg', 'asg-ad']
  AllowAdClientComputeTcpOut  : ['220', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet', 'compute', 'asg', 'asg-ad']
  AllowAdClientComputeUdpOut  : ['230', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet', 'compute', 'asg', 'asg-ad']
  AllowAdServerTcpOut         : ['240', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad', 'asg', 'asg-ad-client']
  AllowAdServerUdpOut         : ['250', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad', 'asg', 'asg-ad-client']
  AllowAdServerComputeTcpOut  : ['260', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad', 'subnet', 'compute']
  AllowAdServerComputeUdpOut  : ['270', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad', 'subnet', 'compute']
  AllowAdServerNetappTcpOut   : ['280', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad', 'subnet', 'netapp']
  AllowAdServerNetappUdpOut   : ['290', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad', 'subnet', 'netapp']

  // CycleCloud
  AllowCycleServerOut         : ['300', 'Outbound', 'Allow', 'Tcp', 'CycleCloud', 'asg', 'asg-cyclecloud', 'asg', 'asg-cyclecloud-client']
  AllowCycleClientOut         : ['310', 'Outbound', 'Allow', 'Tcp', 'CycleCloud', 'asg', 'asg-cyclecloud-client', 'asg', 'asg-cyclecloud']
  AllowComputeCycleClientIn   : ['320', 'Outbound', 'Allow', 'Tcp', 'CycleCloud', 'subnet', 'compute', 'asg', 'asg-cyclecloud']
  AllowCycleWebOut            : ['330', 'Outbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-ondemand', 'asg', 'asg-cyclecloud']

  // PBS
  AllowPbsOut                 : ['340', 'Outbound', 'Allow', '*', 'Pbs', 'asg', 'asg-pbs', 'asg', 'asg-pbs-client']
  AllowPbsClientOut           : ['350', 'Outbound', 'Allow', '*', 'Pbs', 'asg', 'asg-pbs-client', 'asg', 'asg-pbs']
  AllowPbsComputeOut          : ['360', 'Outbound', 'Allow', '*', 'Pbs', 'asg', 'asg-pbs', 'subnet', 'compute']
  AllowPbsClientComputeOut    : ['370', 'Outbound', 'Allow', '*', 'Pbs', 'subnet', 'compute', 'asg', 'asg-pbs']
  AllowComputePbsClientOut    : ['380', 'Outbound', 'Allow', '*', 'Pbs', 'subnet', 'compute', 'asg', 'asg-pbs-client']
  AllowComputeComputePbsOut   : ['381', 'Outbound', 'Allow', '*', 'Pbs', 'subnet', 'compute', 'subnet', 'compute']

  // SLURM
  AllowSlurmComputeOut        : ['385', 'Outbound', 'Allow', '*', 'Slurmd', 'asg', 'asg-ondemand', 'subnet', 'compute']

  // Lustre
  AllowLustreOut              : ['390', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre', 'asg', 'asg-lustre-client']
  AllowLustreClientOut        : ['400', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre-client', 'asg', 'asg-lustre']
  //AllowLustreComputeOut       : ['410', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre', 'subnet', 'compute']
  AllowLustreClientComputeOut : ['420', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'subnet', 'compute', 'asg', 'asg-lustre']
  AllowRobinhoodOut           : ['430', 'Outbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-ondemand', 'asg', 'asg-robinhood']

  // NFS
  AllowNfsOut                 : ['440', 'Outbound', 'Allow', '*', 'Nfs', 'asg', 'asg-nfs-client', 'subnet', 'netapp']
  AllowNfsComputeOut          : ['450', 'Outbound', 'Allow', '*', 'Nfs', 'subnet', 'compute', 'subnet', 'netapp']

  // Telegraf / Grafana
  AllowTelegrafOut            : ['460', 'Outbound', 'Allow', 'Tcp', 'Telegraf', 'asg', 'asg-telegraf', 'asg', 'asg-grafana']
  AllowComputeTelegrafOut     : ['470', 'Outbound', 'Allow', 'Tcp', 'Telegraf', 'subnet', 'compute', 'asg', 'asg-grafana']
  AllowGrafanaOut             : ['480', 'Outbound', 'Allow', 'Tcp', 'Grafana', 'asg', 'asg-ondemand', 'asg', 'asg-grafana']

  // SSH internal rules
  AllowSshFromJumpboxOut      : ['490', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-jumpbox', 'asg', 'asg-ssh']
  AllowSshComputeOut          : ['500', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-ssh', 'subnet', 'compute']
  AllowSshDeployerOut         : ['510', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-deployer', 'asg', 'asg-ssh']
  AllowSshDeployerPackerOut   : ['520', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-deployer', 'subnet', 'admin']
  AllowSshFromComputeOut      : ['530', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'subnet', 'compute', 'asg', 'asg-ssh']
  AllowSshComputeComputeOut   : ['540', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'subnet', 'compute', 'subnet', 'compute']

  // OnDemand NoVNC
  AllowComputeNoVncOut        : ['550', 'Outbound', 'Allow', 'Tcp', 'NoVnc', 'subnet', 'compute', 'asg', 'asg-ondemand']
  AllowNoVncComputeOut        : ['560', 'Outbound', 'Allow', 'Tcp', 'NoVnc', 'asg', 'asg-ondemand', 'subnet', 'compute']

  // Admin and Deployment
  AllowRdpOut                 : ['570', 'Outbound', 'Allow', 'Tcp', 'Rdp', 'asg', 'asg-jumpbox', 'asg', 'asg-rdp']
  AllowWinRMOut               : ['580', 'Outbound', 'Allow', 'Tcp', 'WinRM', 'asg', 'asg-jumpbox', 'asg', 'asg-rdp']
  AllowDnsOut                 : ['590', 'Outbound', 'Allow', '*', 'Dns', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']
  AllowWebDeployerOut         : ['595', 'Outbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-deployer', 'asg', 'asg-ondemand']

  // Guacamole
  AllowGuacamoleRdpOut        : ['610', 'Outbound', 'Allow', 'Tcp', 'Rdp', 'asg', 'asg-guacamole', 'subnet', 'compute']

  // Deny all remaining traffic and allow Internet access
  AllowInternetOutBound       : ['3000', 'Outbound', 'Allow', 'Tcp', 'All', 'tag', 'VirtualNetwork', 'tag', 'Internet']
  DenyVnetOutbound            : ['3100', 'Outbound', 'Deny', '*', 'All', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']

}

// only use for Public IP
var internetNsgRules = {
  AllowInternetSshIn          : ['200', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'tag', 'Internet', 'asg', 'asg-jumpbox']
  AllowInternetHttpIn         : ['210', 'Inbound', 'Allow', 'Tcp', 'Web', 'tag', 'Internet', 'asg', 'asg-ondemand']
}

var hubNsgRules = {
  AllowHubSshIn               : ['200', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'tag', 'VirtualNetwork', 'asg', 'asg-jumpbox']
  AllowHubHttpIn              : ['210', 'Inbound', 'Allow', 'Tcp', 'Web', 'tag', 'VirtualNetwork', 'asg', 'asg-ondemand']
}

var bastionNsgRules = {
  AllowBastionIn              : ['530', 'Inbound', 'Allow', 'Tcp', 'Bastion', 'subnet', 'bastion', 'tag', 'VirtualNetwork']
}

var gatewayNsgRules = {
  AllowInternalWebUsersIn     : ['540', 'Inbound', 'Allow', 'Tcp', 'Web', 'subnet', 'gateway', 'asg', 'asg-ondemand']
}

var securityRules = [ for rule in items(union(
    nsgRules,
    publicIp ? internetNsgRules : hubNsgRules,
    deployBastion ? bastionNsgRules : {},
    deployGateway ? gatewayNsgRules : {}
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


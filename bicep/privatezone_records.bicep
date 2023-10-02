param privateDnsZoneName string = 'hpc.azure'
param adVmNames array
param adVmIps array 

resource privateDnsZoneName_resource 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource privateDnsZoneName_ad 'Microsoft.Network/privateDnsZones/A@2020-06-01' = [ for vmName in adVmNames: {
  parent: privateDnsZoneName_resource
  name: vmName
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: adVmIps[indexOf(adVmNames, vmName)]
      }
    ]
  }
}]

resource privateDnsZoneName_gc_tcp 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_gc._tcp'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 3268
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      }]
  }
}

resource privateDnsZoneName_kerberos_tcp 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_kerberos._tcp'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 88
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_kerberos_tcp_dc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_kerberos._tcp.dc._msdcs'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 88
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_kerberos_udp 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_kerberos._udp'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 88
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_kerberos_default_first_site_name_sites_dc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_kerberos.default-first-site-name._sites.dc._msdcs'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 88
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_kpasswd_tcp 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_kpasswd._tcp'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 464
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_kpasswd_udp 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_kpasswd._udp'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 464
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_ldap_tcp 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap._tcp'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 389
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_ldap_tcp_dc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap._tcp.dc._msdcs'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 389
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_ldap_tcp_gc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap._tcp.gc._msdcs'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 3268
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_ldap_tcp_pdc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap._tcp.pdc._msdcs'
  properties: {
    ttl: 3600
    srvRecords: [
      {
        port: 389
        priority: 0
        target: '${adVmNames[0]}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_ldap_default_first_site_name_sites_dc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap.default-first-site-name._sites.dc._msdcs'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 389
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

resource privateDnsZoneName_ldap_default_first_site_name_sites_gc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2020-06-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap.default-first-site-name._sites.gc._msdcs'
  properties: {
    ttl: 3600
    srvRecords: [ for vmName in adVmNames: {
        port: 3268
        priority: 0
        target: '${vmName}.${privateDnsZoneName}.'
        weight: 100
      } ]
  }
}

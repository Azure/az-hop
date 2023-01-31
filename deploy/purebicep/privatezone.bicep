param privateDnsZoneName string = 'hpc.azure'
param vnetId string
param adVmName string
param adVmIp string

resource privateDnsZoneName_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneName_ad 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: adVmName
  properties: {
    metadata: {
    }
    ttl: 3600
    aRecords: [
      {
        ipv4Address: adVmIp
      }
    ]
  }
}

resource privateDnsZoneName_gc_tcp 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_gc._tcp'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 3268
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_kerberos_tcp 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_kerberos._tcp'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 88
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_kerberos_tcp_dc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_kerberos._tcp.dc._msdcs'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 88
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_kerberos_udp 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_kerberos._udp'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 88
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_kerberos_default_first_site_name_sites_dc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_kerberos.default-first-site-name._sites.dc._msdcs'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 88
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_kpasswd_tcp 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_kpasswd._tcp'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 464
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_kpasswd_udp 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_kpasswd._udp'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 464
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_ldap_tcp 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap._tcp'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 389
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_ldap_tcp_dc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap._tcp.dc._msdcs'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 389
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_ldap_tcp_gc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap._tcp.gc._msdcs'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 3268
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_ldap_tcp_pdc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap._tcp.pdc._msdcs'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 389
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_ldap_default_first_site_name_sites_dc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap.default-first-site-name._sites.dc._msdcs'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 389
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_ldap_default_first_site_name_sites_gc_msdcs 'Microsoft.Network/privateDnsZones/SRV@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: '_ldap.default-first-site-name._sites.gc._msdcs'
  properties: {
    metadata: {
    }
    ttl: 3600
    srvRecords: [
      {
        port: 3268
        priority: 0
        target: '${adVmName}.${privateDnsZoneName}.'
        weight: 100
      }
    ]
  }
}

resource privateDnsZoneName_az_hop 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZoneName_resource
  name: 'az-hop'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

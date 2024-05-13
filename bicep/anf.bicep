targetScope = 'resourceGroup'

param location string
param resourcePostfix string
param dualProtocol bool
param subnetId string
param adUser string
@secure()
param adPassword string
param adDns string
param serviceLevel string
param sizeGB int


resource anfAccount 'Microsoft.NetApp/netAppAccounts@2023-07-01' = {
  name: 'azhop-${resourcePostfix}'
  location: location
  
  properties: dualProtocol ? {
    activeDirectories: [
      {
        username: adUser
        password: adPassword
        dns: adDns
        smbServerName: 'anf'
        domain: 'hpc.azure' 
      }
    ]
  } : {}
}

resource anfPool 'Microsoft.NetApp/netAppAccounts/capacityPools@2023-07-01' = {
  name: 'anfpool-${resourcePostfix}'
  location: location
  parent: anfAccount
  properties: {
    serviceLevel: serviceLevel
    size: sizeGB * 1024 * 1024 * 1024
  }
}

resource anfHome 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes@2023-07-01' = {
  name: 'anfhome'
  location: location
  parent: anfPool
  properties: {
    creationToken: 'home-${resourcePostfix}'
    serviceLevel: serviceLevel
    networkFeatures: 'Standard'
    subnetId: subnetId
    protocolTypes: union([
        'NFSv3'
      ], dualProtocol ? [
        'CIFS'
      ] : []
    )
    securityStyle: 'unix'
    usageThreshold: sizeGB * 1024 * 1024 * 1024

    exportPolicy: {
      rules: [
        {
            ruleIndex: 1
            unixReadOnly: false
            unixReadWrite: true
            cifs: false
            nfsv3: true
            nfsv41: false
            allowedClients: '0.0.0.0/0'
            kerberos5ReadOnly: false
            kerberos5ReadWrite: false
            kerberos5iReadOnly: false
            kerberos5iReadWrite: false
            kerberos5pReadOnly: false
            kerberos5pReadWrite: false
            hasRootAccess: true
            chownMode: 'Restricted'
        }
      ]
    }
  }
}

output anf_account_name string = 'azhop-${resourcePostfix}'
output anf_pool_name string = 'anfpool-${resourcePostfix}'
output anf_volume_name string = 'anfhome'
output nfs_home_ip string = anfHome.properties.mountTargets[0].ipAddress
output nfs_home_path string = 'home-${resourcePostfix}'
output nfs_home_opts string = 'rw,hard,rsize=262144,wsize=262144,vers=3,tcp,_netdev'

@description('Name of new or existing vnet to which Azure Bastion should be deployed')
param vnetName string = 'hpcvnet'

@description('IP prefix for available addresses in vnet address space')
param vnetIpPrefix string = '10.0.0.0/16'

@description('Admin subnet IP prefix')
param adminSubnetIpPrefix string = '10.0.1.0/24'

@description('deploy name')
param deployName string = 'deployer'

@description('deploy VM size')
param deployVmSize string = 'Standard_B2ms'

@description('deploy username')
param deployUsername string

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param deployKey string

@description('Azure region to use')
param location string = resourceGroup().location

var adminSubnetName = 'admin'
var deployNicName = '${deployName}-nic'
var deployNsgName = '${deployName}-nsg'
var deployOsDiskType = 'Standard_LRS'

var setupScriptTpl = '''
#cloud-config
write_files:
- owner: root:root
  path: /root/deploy.sh
  permissions: '0700'
  content: |
    cd /root
    git clone -b private_jumpbox --recursive https://github.com/Azure/az-hop.git
    cd az-hop
    sudo ./toolset/scripts/install.sh
    ln -s ../config.yml
    sudo apt install -y azure-cli
    az login -i
    #az vm image terms accept --offer azurehpc-lustre --publisher azhpc --plan azurehpc-lustre-2_12
    ./build.sh -a apply
    ./bin/create_passwords.sh
    ./install.sh
- owner: root:root
  path: /root/config.yml
  content: |
    ---
    location: LOCATION
    resource_group: RESOURCE_GROUP
    use_existing_rg: true
    tags:
      env: dev
      project: azhop
    anf:
      homefs_size_tb: 4
      homefs_service_level: Standard
      dual_protocol: false # true to enable SMB support. false by default
    
    mounts:
      home:
        mountpoint: /anfhome # /sharedhome for example
        server: '{{anf_home_ip}}' # Specify an existing NFS server name or IP, when using the ANF built in use '{{anf_home_ip}}'
        export: '{{anf_home_path}}' # Specify an existing NFS export directory, when using the ANF built in use '{{anf_home_path}}'
    
    admin_user: hpcadmin
    key_vault_readers: #<object_id>
    network:
      create_nsg: true
      vnet:
        name: hpcvnet # Optional - default to hpcvnet
        id: /subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/hpcvnet
        address_space: "10.0.0.0/16" # Optional - default to "10.0.0.0/16"
        subnets: # all subnets are optionals
          frontend:
            name: frontend
            address_prefixes: "10.0.0.0/24"
            create: true # create the subnet if true. default to true when not specified, default to false if using an existing VNET when not specified
          admin:
            name: admin
            address_prefixes: "10.0.1.0/24"
            create: false
          netapp:
            name: netapp
            address_prefixes: "10.0.2.0/24"
            create: true
          ad:
            name: ad
            address_prefixes: "10.0.3.0/28"
            create: true
          compute:
            name: compute
            address_prefixes: "10.0.16.0/20"
            create: true
    
    locked_down_network:
      enforce: false
      jb_public_ip: false
      public_ip: false # Enable public IP creation OnDemand and create images. Default to true
    
    linux_base_image: "OpenLogic:CentOS:7_9-gen2:latest" # publisher:offer:sku:version or image_id
    windows_base_image: "MicrosoftWindowsServer:WindowsServer:2016-Datacenter-smalldisk:latest" # publisher:offer:sku:version or image_id
    
    jumpbox:
      vm_size: Standard_B2ms
    ad:
      vm_size: Standard_B2ms
      hybrid_benefit: false # Enable hybrid benefit for AD, default to false
    ondemand:
      vm_size: Standard_D4s_v5
      generate_certificate: true # Generate an SSL certificate for the OnDemand portal. Default to true
    grafana:
      vm_size: Standard_B2ms
    scheduler:
      vm_size: Standard_B2ms
    cyclecloud:
      vm_size: Standard_B2ms
    winviz:
      vm_size: Standard_D4s_v3
      create: false # Create an always running windows node, false by default
    
    lustre:
      rbh_sku: "Standard_D8d_v4"
      mds_sku: "Standard_D8d_v4"
      oss_sku: "Standard_D32d_v4"
      oss_count: 2
      hsm_max_requests: 8
      mdt_device: "/dev/sdb"
      ost_device: "/dev/sdb"
      hsm:
        storage_account: #existing_storage_account_name
        storage_container: #only_used_with_existing_storage_account
    users:
      - { name: clusteradmin, uid: 10001, gid: 5000, admin: true, sudo: true }
      - { name: clusteruser, uid: 10002, gid: 5000 }
    groups: # Not used today => To be used in the future
      - name: users
        gid: 5000
    
    
    queue_manager: openpbs
    
    slurm:
      accounting_enabled: false
      enroot_enabled: false
    
    authentication:
      httpd_auth: basic # oidc or basic
    
    images:
    queues:
      - name: execute # name of the Cycle Cloud node array
        vm_size: Standard_F2s_v2
        max_core_count: 1024
        image: OpenLogic:CentOS-HPC:7_9-gen2:latest
        EnableAcceleratedNetworking: false
        spot: false
        ColocateNodes: false
        enroot_enabled: false
      - name: hc44rs
        vm_size: Standard_HC44rs
        max_core_count: 440
        image: OpenLogic:CentOS-HPC:7_9-gen2:latest
        spot: true
      - name: hb120v2
        vm_size: Standard_HB120rs_v2
        max_core_count: 1200
        image: OpenLogic:CentOS-HPC:7_9-gen2:latest
        spot: true
      - name: hb120v3
        vm_size: Standard_HB120rs_v3
        max_core_count: 1200
        image: OpenLogic:CentOS-HPC:7_9-gen2:latest
        spot: true
      - name: viz3d
        vm_size: Standard_NV12s_v3
        max_core_count: 48
        image: OpenLogic:CentOS-HPC:7_9-gen2:latest
        ColocateNodes: false
        spot: false
      - name: largeviz3d
        vm_size: Standard_NV48s_v3
        max_core_count: 96
        image: OpenLogic:CentOS-HPC:7_9-gen2:latest
        ColocateNodes: false
        spot: false
      - name: viz
        vm_size: Standard_D8s_v3
        max_core_count: 200
        image: OpenLogic:CentOS-HPC:7_9-gen2:latest
        ColocateNodes: false
        spot: false

runcmd:
- cd /root
- ./deploy.sh
'''
var setupScript = replace(replace(replace(setupScriptTpl, 'SUBSCRIPTION_ID', subscription().id), 'LOCATION', location), 'RESOURCE_GROUP', resourceGroup().name)

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetIpPrefix
      ]
    }
    subnets: [
      {
        name: adminSubnetName
        properties: {
          addressPrefix: adminSubnetIpPrefix
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.Sql'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                location
              ]
            }
          ]
        }
      }
    ]
  }
}

resource adminSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  parent: virtualNetwork
  name: adminSubnetName
  properties: {
    addressPrefix: adminSubnetIpPrefix
  }
}

resource deployNsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: deployNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource deployNic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: deployNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${deployName}-ipconfig'
        properties: {
          subnet: {
            id: adminSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: deployNsg.id
    }
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${deployName}-pip'
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

var contributorId = resourceId('microsoft.authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
//var readerId = resourceId('microsoft.authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
var userAccessAdministratorId = resourceId('microsoft.authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
var contributorRa = guid(managedIdentity.name, contributorId, subscription().id)
//var subscriptionRa = guid(managedIdentity.name, readerId, subscription().id)
var UserAccessAdminitratorRa = guid(managedIdentity.name, userAccessAdministratorId, subscription().id)
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${deployName}-mi'
  location: location
}
resource managedIdentityContributor 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: contributorRa
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
//resource managedIdentityReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//  name: subscriptionRa
//  scope: resourceGroup()
//  properties: {
//    roleDefinitionId: readerId
//    principalId: managedIdentity.properties.principalId
//    principalType: 'ServicePrincipal'
//  }
//}
resource managedIdentityUserAccessAdminitrator 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: UserAccessAdminitratorRa
  scope: resourceGroup()
  properties: {
    roleDefinitionId: userAccessAdministratorId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: deployName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: deployVmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: deployOsDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: deployNic.id
        }
      ]
    }
    osProfile: {
      computerName: deployName
      adminUsername: deployUsername
      customData: base64(setupScript)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${deployUsername}/.ssh/authorized_keys'
              keyData: deployKey
            }
          ]
        }
      }
    }
  }
}

targetScope = 'resourceGroup'

var azhopResourceGroupName = resourceGroup().name

@description('Azure region to use')
param location string

@description('Branch name to deploy from - Default main')
param branchName string = 'main'

@description('Autogenerate passwords and SSH key pair.')
param autogenerateSecrets bool = false

@description('SSH Public Key for the Virtual Machines.')
@secure()
param adminSshPublicKey string = ''

@description('SSH Private Key for the Virtual Machines.')
@secure()
param adminSshPrivateKey string = ''

@description('The Windows/Active Directory password.')
@secure()
param adminPassword string = ''

@description('Password for the Slurm accounting admin user')
@secure()
param databaseAdminPassword string = ''

@description('Identity of the deployer if not deploying from a deployer VM')
param loggedUserObjectId string = ''

@description('Input configuration file in json format')
param azhopConfig object

var resourcePostfix = '${uniqueString(subscription().subscriptionId, azhopResourceGroupName)}x'

// Local variables to help in the simplication as functions doesn't exists
var enablePublicIP = contains(azhopConfig, 'locked_down_network') ? azhopConfig.locked_down_network.public_ip : true
var jumpboxSshPort = deployJumpbox ? (contains(azhopConfig.jumpbox, 'ssh_port') ? azhopConfig.jumpbox.ssh_port : 22) : 22
var deployerSshPort = deployDeployer ? (contains(azhopConfig.deployer, 'ssh_port') ? azhopConfig.deployer.ssh_port : 22) : 22
var ccportalSshPort = cycleCloudAsDeployer ? (contains(azhopConfig.cyclecloud, 'ssh_port') ? azhopConfig.cyclecloud.ssh_port : 22) : 22
var incomingSSHPort = deployDeployer ? deployerSshPort : (cycleCloudAsDeployer ?  ccportalSshPort : jumpboxSshPort )


var deployLustre = contains(azhopConfig, 'lustre') && contains(azhopConfig.lustre, 'create') ? azhopConfig.lustre.create : false
var deployJumpbox = contains(azhopConfig, 'jumpbox') ? true : false
var deployDeployer = contains(azhopConfig, 'deployer') ? true : false
var deployGrafana = contains(azhopConfig, 'monitoring') && contains(azhopConfig.monitoring, 'grafana') ? azhopConfig.monitoring.grafana : true
var deployOnDemand = contains(azhopConfig, 'ondemand') ? true : false
var cycleCloudAsDeployer = contains(azhopConfig, 'cyclecloud') && contains(azhopConfig.cyclecloud, 'use_as_deployer') ? azhopConfig.cyclecloud.use_as_deployer : false

var useExistingAD = contains(azhopConfig, 'domain') ? azhopConfig.domain.use_existing_dc : false
var userAuth = contains(azhopConfig, 'authentication') && contains(azhopConfig.authentication, 'user_auth') ? azhopConfig.authentication.user_auth : 'ad'
var createAD = ! useExistingAD && (userAuth == 'ad')

var highAvailabilityForAD = contains(azhopConfig, 'ad') && contains(azhopConfig.ad, 'high_availability') ? azhopConfig.ad.high_availability : false

var linuxBaseImage = contains(azhopConfig, 'linux_base_image') ? azhopConfig.linux_base_image : 'OpenLogic:CentOS:7_9-gen2:latest'
var linuxBasePlan = contains(azhopConfig, 'linux_base_plan') ? azhopConfig.linux_base_plan : ''
var windowsBaseImage = contains(azhopConfig, 'windows_base_image') ? azhopConfig.windows_base_image : 'MicrosoftWindowsServer:WindowsServer:2019-Datacenter-smalldisk:latest'
var cyclecloudBaseImage = contains(azhopConfig.cyclecloud, 'image') ? azhopConfig.cyclecloud.image : linuxBaseImage
var cyclecloudBasePlan = contains(azhopConfig.cyclecloud, 'plan') ? azhopConfig.cyclecloud.plan : linuxBasePlan

var createDatabase = queue_manager == 'slurm' && slurm_accounting_enabled
var slurm_accounting_enabled = contains(azhopConfig, 'slurm') && contains(azhopConfig.slurm, 'accounting_enabled') ? azhopConfig.slurm.accounting_enabled : false 

var computeMIoption = contains(azhopConfig, 'compute_vm_identity')
var createComputeMI = computeMIoption && contains(azhopConfig.compute_vm_identity, 'create') ? azhopConfig.compute_vm_identity.create : false
var computeMIname =   computeMIoption && contains(azhopConfig.compute_vm_identity, 'name') ? azhopConfig.compute_vm_identity.name : 'compute-mi'
var existingComputeMIrg = !createComputeMI && computeMIoption && contains(azhopConfig.compute_vm_identity, 'resource_group') ? azhopConfig.compute_vm_identity.resource_group : ''

var create_anf = contains(azhopConfig, 'anf') && contains(azhopConfig.anf, 'create') ? azhopConfig.anf.create : (contains(azhopConfig, 'anf') ? true : false)

var nsgTargetForDC = {
  type: useExistingAD ? 'ips' : 'asg'
  target: useExistingAD ? azhopConfig.domain.existing_dc_details.domain_controller_ip_addresses : 'asg-ad'
}

var vmNamesMap = {
  ad : contains(azhopConfig, 'ad') && contains(azhopConfig.ad, 'name') ? azhopConfig.ad.name : 'ad'
  ad2 : contains(azhopConfig, 'ad') && contains(azhopConfig.ad, 'ha_name') ? azhopConfig.ad.ha_name : 'ad2'
  deployer: contains(azhopConfig, 'deployer') && contains(azhopConfig.deployer, 'name') ? azhopConfig.deployer.name : 'deployer'
  jumpbox: contains(azhopConfig, 'jumpbox') && contains(azhopConfig.jumpbox, 'name') ? azhopConfig.jumpbox.name : 'jumpbox'
  ccportal: contains(azhopConfig, 'cyclecloud') && contains(azhopConfig.cyclecloud, 'name') ? azhopConfig.cyclecloud.name : 'ccportal'
  ondemand: contains(azhopConfig, 'ondemand') && contains(azhopConfig.ondemand, 'name') ? azhopConfig.ondemand.name : 'ondemand'
  scheduler: contains(azhopConfig, 'scheduler') && contains(azhopConfig.scheduler, 'name') ? azhopConfig.scheduler.name : 'scheduler'
  grafana: contains(azhopConfig, 'grafana') && contains(azhopConfig.grafana, 'name') ? azhopConfig.grafana.name : 'grafana'
}
var queue_manager= contains(azhopConfig, 'queue_manager') ? azhopConfig.queue_manager : 'openpbs'
// Convert the azhop configuration file to a pivot format used for the deployment
var config = {
  admin_user: azhopConfig.admin_user
  keyvault_readers: contains(azhopConfig, 'key_vault_readers') ? ( empty(azhopConfig.key_vault_readers) ? [] : [ azhopConfig.key_vault_readers ] ) : []

  public_ip: enablePublicIP
  deploy_gateway: contains(azhopConfig, 'vpn_gateway') && contains(azhopConfig.vpn_gateway, 'create') ? azhopConfig.vpn_gateway.create : false
  deploy_bastion: contains(azhopConfig, 'bastion') && contains(azhopConfig.bastion, 'create') ? azhopConfig.bastion.create : false
  deploy_lustre: deployLustre


  lock_down_network: {
    enforce: contains(azhopConfig, 'locked_down_network') && contains(azhopConfig.locked_down_network, 'enforce') ? azhopConfig.locked_down_network.enforce : false
    grant_access_from: contains(azhopConfig, 'locked_down_network') && contains(azhopConfig.locked_down_network, 'grant_access_from') ? ( empty(azhopConfig.locked_down_network.grant_access_from) ? [] : [ azhopConfig.locked_down_network.grant_access_from ] ) : []
  }

  nat_gateway: {
    create: contains(azhopConfig, 'nat_gateway') && contains(azhopConfig.nat_gateway, 'create') ? azhopConfig.nat_gateway.create : false
    name: contains(azhopConfig, 'nat_gateway') && contains(azhopConfig.nat_gateway, 'name') ? azhopConfig.nat_gateway.name : 'natgw-${resourcePostfix}'
  }

  queue_manager: queue_manager

  slurm: {
    admin_user: contains(azhopConfig, 'database') && contains(azhopConfig.database, 'user') ? azhopConfig.database.user : 'sqladmin'
    accounting_enabled: contains(azhopConfig, 'slurm') && contains(azhopConfig.slurm, 'accounting_enabled') ? azhopConfig.slurm.accounting_enabled : false
  }

  private_dns: {
    create: contains(azhopConfig, 'private_dns') && contains(azhopConfig.private_dns, 'create') ? azhopConfig.private_dns.create : false
    name: contains(azhopConfig, 'private_dns') && contains(azhopConfig.private_dns, 'name') ? azhopConfig.private_dns.name : 'hpc.azure'
    registration_enabled: contains(azhopConfig, 'private_dns') && contains(azhopConfig.private_dns, 'registration_enabled') ? azhopConfig.private_dns.registration_enabled : false
  }


  domain: {
    name : contains(azhopConfig, 'domain') ? azhopConfig.domain.name : 'hpc.azure'
    domain_join_user: createAD ? {
      username: azhopConfig.admin_user
    } : useExistingAD ? {
      username: azhopConfig.domain.domain_join_user.username
      password_key_vault_name: azhopConfig.domain.domain_join_user.password_key_vault_name
      password_key_vault_resource_group_name: azhopConfig.domain.domain_join_user.password_key_vault_resource_group_name
      password_key_vault_secret_name: azhopConfig.domain.domain_join_user.password_key_vault_secret_name
    } : {
      username: ''
    }
    domain_controlers : createAD ? (! highAvailabilityForAD ? [vmNamesMap.ad] : [vmNamesMap.ad, vmNamesMap.ad2]) : useExistingAD ? azhopConfig.domain.existing_dc_details.domain_controller_names : []
    ldap_server: createAD ? vmNamesMap.ad : useExistingAD ? azhopConfig.domain.existing_dc_details.domain_controller_names[0] : ''
  }

  key_vault_name: contains(azhopConfig, 'azure_key_vault') ? azhopConfig.azure_key_vault.name : 'kv${resourcePostfix}'
  storage_account_name: contains(azhopConfig, 'azure_storage_account') ? azhopConfig.azure_storage_account.name : 'azhop${resourcePostfix}'
  db_name: contains(azhopConfig, 'database') && contains(azhopConfig.database, 'name') ? azhopConfig.database.name : 'mysql-${resourcePostfix}'

  deploy_grafana: deployGrafana
  deploy_ondemand: deployOnDemand
  deploy_sig: contains(azhopConfig, 'image_gallery') && contains(azhopConfig.image_gallery, 'create') ? azhopConfig.image_gallery.create : false

  // Default home directory is ANF
  homedir_type: contains(azhopConfig.mounts.home, 'type') ? azhopConfig.mounts.home.type : 'existing'
  homedir_mountpoint: azhopConfig.mounts.home.mountpoint

  lustre: {
    create: deployLustre ? true : false
    sku: contains(azhopConfig, 'lustre') && contains(azhopConfig.lustre, 'sku') ? azhopConfig.lustre.sku : 'AMLFS-Durable-Premium-250'
    capacity: contains(azhopConfig, 'lustre') && contains(azhopConfig.lustre, 'capacity') ? azhopConfig.lustre.capacity : 8
  }

  anf: {
    create: create_anf
    dual_protocol: contains(azhopConfig, 'anf') && contains(azhopConfig.anf, 'dual_protocol') ? azhopConfig.anf.dual_protocol : false
    service_level: contains(azhopConfig, 'anf') && contains(azhopConfig.anf, 'homefs_service_level') ? azhopConfig.anf.homefs_service_level : 'Standard'
    size_gb: contains(azhopConfig, 'anf') && contains(azhopConfig.anf, 'homefs_size_tb') ? azhopConfig.anf.homefs_size_tb*1024 : 4096
  }

  azurefiles: {
    create: contains(azhopConfig, 'azurefiles') && contains(azhopConfig.azurefiles, 'create') ? azhopConfig.azurefiles.create : false
    size_gb: contains(azhopConfig, 'azurefiles') && contains(azhopConfig.azurefiles, 'size_gb') ? azhopConfig.azurefiles.size_gb : 1024
  }

  vnet: {
    tags: contains(azhopConfig.network.vnet,'tags') ? azhopConfig.network.vnet.tags : {}
    name: azhopConfig.network.vnet.name
    cidr: azhopConfig.network.vnet.address_space
    subnets: union (
      {
      frontend: {
        name: contains(azhopConfig.network.vnet.subnets.frontend, 'name') ? azhopConfig.network.vnet.subnets.frontend.name : 'frontend'
        cidr: azhopConfig.network.vnet.subnets.frontend.address_prefixes
        nat_gateway: true
        service_endpoints: [
          'Microsoft.Storage'
        ]
      }
      admin: {
        name: contains(azhopConfig.network.vnet.subnets.admin, 'name') ? azhopConfig.network.vnet.subnets.admin.name : 'admin'
        cidr: azhopConfig.network.vnet.subnets.admin.address_prefixes
        nat_gateway: true
        service_endpoints: [
          'Microsoft.KeyVault'
          'Microsoft.Storage'
        ]
      }
      compute: {
        name: contains(azhopConfig.network.vnet.subnets.compute, 'name') ? azhopConfig.network.vnet.subnets.compute.name : 'compute'
        cidr: azhopConfig.network.vnet.subnets.compute.address_prefixes
        nat_gateway: true
        service_endpoints: [
          'Microsoft.Storage'
        ]
      }
    },
    createDatabase ? {
      database: {
        name: contains(azhopConfig.network.vnet.subnets.database, 'name') ? azhopConfig.network.vnet.subnets.database.name : 'database'
        cidr: azhopConfig.network.vnet.subnets.database.address_prefixes
        delegations: [
          'Microsoft.DBforMySQL/flexibleServers'
        ]
      }
    } : {},
    create_anf ? {
      netapp: {
        name: contains(azhopConfig.network.vnet.subnets.netapp, 'name') ? azhopConfig.network.vnet.subnets.netapp.name : 'netapp'
        cidr: azhopConfig.network.vnet.subnets.netapp.address_prefixes
        delegations: [
          'Microsoft.Netapp/volumes'
        ]
      }
    } : {},
    deployLustre ? {
      lustre: {
        name: contains(azhopConfig.network.vnet.subnets.lustre, 'name') ? azhopConfig.network.vnet.subnets.lustre.name : 'lustre'
        cidr: azhopConfig.network.vnet.subnets.lustre.address_prefixes
      }
    } : {},
    createAD ? {
      ad: {
        name: contains(azhopConfig.network.vnet.subnets.ad, 'name') ? azhopConfig.network.vnet.subnets.ad.name : 'ad'
        cidr: azhopConfig.network.vnet.subnets.ad.address_prefixes
        nat_gateway: true
      }
    } : {},
    contains(azhopConfig.network.vnet.subnets,'bastion') ? {
      bastion: {
        apply_nsg: true
        name: 'AzureBastionSubnet'
        cidr: azhopConfig.network.vnet.subnets.bastion.address_prefixes
      }
    } : {},
    contains(azhopConfig.network.vnet.subnets,'outbounddns') ? {
      outbounddns: {
        name: contains(azhopConfig.network.vnet.subnets.outbounddns, 'name') ? azhopConfig.network.vnet.subnets.outbounddns.name : 'outbounddns'
        cidr: azhopConfig.network.vnet.subnets.outbounddns.address_prefixes
        delegations: [
          'Microsoft.Network/dnsResolvers'
        ]
      }
    } : {},
    contains(azhopConfig.network.vnet.subnets,'gateway') ? {
      gateway: {
        apply_nsg: false
        name: 'GatewaySubnet'
        cidr: azhopConfig.network.vnet.subnets.gateway.address_prefixes
      }
    } : {}
    )
    peerings: contains(azhopConfig.network,'peering') ? azhopConfig.network.peering : []
  }

  images: {
    ubuntu: {
      ref: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
    }
    linux_base: {
      plan: linuxBasePlan
      ref: contains(linuxBaseImage, '/') ? {
        id: linuxBaseImage
      } : {
        publisher: split(linuxBaseImage,':')[0]
        offer: split(linuxBaseImage,':')[1]
        sku: split(linuxBaseImage,':')[2]
        version: split(linuxBaseImage,':')[3]
      }
    }
    win_base: {
      ref: contains(windowsBaseImage, '/') ? {
        id: windowsBaseImage
      } : {
        publisher: split(windowsBaseImage,':')[0]
        offer: split(windowsBaseImage,':')[1]
        sku: split(windowsBaseImage,':')[2]
        version: split(windowsBaseImage,':')[3]
      }
    }
    cyclecloud_base: {
      plan: cyclecloudBasePlan
      ref: contains(cyclecloudBaseImage, '/') ? {
        id: cyclecloudBaseImage
      } : {
        publisher: split(cyclecloudBaseImage,':')[0]
        offer: split(cyclecloudBaseImage,':')[1]
        sku: split(cyclecloudBaseImage,':')[2]
        version: split(cyclecloudBaseImage,':')[3]
      }
    }
  }


  vms: union(
    deployOnDemand ? {
      ondemand: {
        subnet: 'frontend'
        name: vmNamesMap.ondemand
        sku: azhopConfig.ondemand.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        pip: enablePublicIP
        asgs: union(
          [ 'asg-ssh', 'asg-ondemand', 'asg-nfs-client', 'asg-sched', 'asg-cyclecloud-client' ],
          deployGrafana ? ['asg-telegraf'] : [],
          (userAuth == 'ad') ? ['asg-ad-client'] : [],
          deployLustre ? [ 'asg-lustre-client' ] : []
        )
      }
    } : {},
    {
      ccportal: {
        subnet: deployOnDemand ? 'admin' : 'frontend'
        name: vmNamesMap.ccportal
        sku: azhopConfig.cyclecloud.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'cyclecloud_base'
        pip: enablePublicIP && !deployOnDemand
        sshPort: cycleCloudAsDeployer ? incomingSSHPort : 22
        deploy_script: cycleCloudAsDeployer ? replace(replace(loadTextContent('install.sh'), '__INSERT_AZHOP_BRANCH__', branchName), '__SSH_PORT__', string(incomingSSHPort)) : ''
        datadisks: [
          {
            name: '${vmNamesMap.ccportal}-datadisk0'
            disksku: 'Premium_LRS'
            size: split(cyclecloudBaseImage,':')[0] == 'azurecyclecloud' ? 0 : 128
            caching: 'ReadWrite'
            createOption: split(cyclecloudBaseImage,':')[0] == 'azurecyclecloud' ? 'FromImage' : 'Empty'
          }
        ]
        identity: {
          keyvault: cycleCloudAsDeployer ? {
            secret_permissions: [ 'All' ]
          } : {}
          roles: [
            'Contributor'
          ]
        }
        asgs: union(
          [ 'asg-ssh', 'asg-cyclecloud' ],
          cycleCloudAsDeployer ? [ 'asg-jumpbox', 'asg-deployer' ] : [],
          (userAuth == 'ad') ? ['asg-ad-client'] : [],
          deployGrafana ? ['asg-telegraf'] : []
        )
      }
      scheduler: {
        subnet: 'admin'
        name: vmNamesMap.scheduler
        sku: azhopConfig.scheduler.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        asgs: union(
          [ 'asg-ssh', 'asg-sched', 'asg-cyclecloud-client', 'asg-nfs-client' ],
          (userAuth == 'ad') ? ['asg-ad-client'] : [],
          deployGrafana ? ['asg-telegraf'] : [],
          createDatabase ? ['asg-mysql-client'] : []
        )
      }
    },
    createAD ? {
      ad: {
        subnet: 'ad'
        windows: true
        name: vmNamesMap.ad
        ahub: contains(azhopConfig.ad, 'hybrid_benefit') ? azhopConfig.ad.hybrid_benefit : false
        sku: azhopConfig.ad.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'win_base'
        asgs: [ 'asg-ad', 'asg-rdp', 'asg-ad-client' ]
      }
    } : {},
    deployDeployer ? {
      deployer: {
          subnet: 'frontend'
          name: vmNamesMap.deployer
          sku: azhopConfig.deployer.vm_size
          osdisksku: 'Standard_LRS'
          image: 'ubuntu'
          pip: enablePublicIP
          sshPort: incomingSSHPort
          asgs: union( 
            [ 'asg-ssh', 'asg-jumpbox', 'asg-deployer' ],
            deployGrafana ? ['asg-telegraf'] : []
            )    
          deploy_script: replace(replace(loadTextContent('install.sh'), '__INSERT_AZHOP_BRANCH__', branchName), '__SSH_PORT__', string(incomingSSHPort))
          identity: {
            keyvault: {
              secret_permissions: [ 'All' ]
            }
            roles: [
              'Contributor'
              'UserAccessAdministrator'
            ]
          }
        }
    } : {},
    highAvailabilityForAD ? {
      ad2: {
        subnet: 'ad'
        windows: true
        ahub: contains(azhopConfig.ad, 'hybrid_benefit') ? azhopConfig.ad.hybrid_benefit : false
        name: vmNamesMap.ad2
        sku: azhopConfig.ad.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'win_base'
        asgs: [ 'asg-ad', 'asg-rdp', 'asg-ad-client' ]
      }
    } : {} ,
    deployJumpbox ? {
      jumpbox: {
        subnet: 'frontend'
        name: vmNamesMap.jumpbox
        sku: azhopConfig.jumpbox.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        pip: enablePublicIP
        sshPort: incomingSSHPort
        asgs: union(
          [ 'asg-ssh', 'asg-jumpbox' ],
          deployGrafana ? ['asg-telegraf'] : []
          )  
        deploy_script: incomingSSHPort != 22 ? replace(loadTextContent('jumpbox.yml'), '__SSH_PORT__', string(incomingSSHPort)) : ''
      }
    } : {},
    deployGrafana ? {
      grafana: {
        subnet: 'admin'
        name: vmNamesMap.grafana
        sku: azhopConfig.grafana.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        asgs: union (
          [ 'asg-ssh', 'asg-grafana', 'asg-telegraf', 'asg-nfs-client' ],
          (userAuth == 'ad') ? ['asg-ad-client'] : []
        )
      }
    } : {}
  )

  asg_names: union([ 'asg-ssh', 'asg-jumpbox', 'asg-sched', 'asg-cyclecloud', 'asg-cyclecloud-client', 'asg-nfs-client' ],
    deployLustre                           ? [ 'asg-lustre-client' ] : [],
    deployGrafana                          ? [ 'asg-grafana', 'asg-telegraf' ] : [],
    (userAuth == 'ad')                     ? ['asg-rdp', 'asg-ad', 'asg-ad-client'] : [],
    deployOnDemand                         ? ['asg-ondemand']: [],
    createDatabase                         ? ['asg-mysql-client']: [],
    deployDeployer || cycleCloudAsDeployer ? ['asg-deployer']: []
  )

  service_ports: {
    All: ['0-65535']
    Bastion: (incomingSSHPort == 22) ? ['22', '3389'] : ['22', string(incomingSSHPort), '3389']
    Web: ['443', '80']
    Ssh: ['22']
    HubSsh: [string(incomingSSHPort)]
    // DNS, Kerberos, RpcMapper, Ldap, Smb, KerberosPass, LdapSsl, LdapGc, LdapGcSsl, AD Web Services, RpcSam
    DomainControlerTcp: ['53', '88', '135', '389', '445', '464', '636', '3268', '3269', '9389', '49152-65535']
    // DNS, Kerberos, W32Time, NetBIOS, Ldap, KerberosPass, LdapSsl
    DomainControlerUdp: ['53', '88', '123', '138', '389', '464', '636']
    // Web, NoVNC, WebSockify
    NoVnc: ['80', '443', '5900-5910', '61001-61010']
    Dns: ['53']
    Rdp: ['3389']
//    Pbs: ['6200', '15001-15009', '17001', '32768-61000']
//    Slurm: ['6817-6819']
    Shed: (queue_manager == 'slurm') ? ['6817-6819', '59000-61000'] : ['6200', '15001-15009', '17001', '32768-61000']
    Lustre: ['988', '1019-1023']
    Nfs: ['111', '635', '2049', '4045', '4046']
    SMB: ['445']
    Telegraf: ['8086']
    Grafana: ['3000']
    // HTTPS, AMQP
    CycleCloud: ['9443', '5672']
    MySQL: ['3306', '33060']
    WinRM: ['5985', '5986']
  }

  nsg_rules: {
      default: {
      //
      // INBOUND RULES
      //
    
      // SSH internal rules
      AllowSshFromJumpboxIn       : ['320', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-jumpbox', 'asg', 'asg-ssh']
      AllowSshFromComputeIn       : ['330', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'subnet', 'compute', 'asg', 'asg-ssh']
      AllowSshToComputeIn         : ['360', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-ssh', 'subnet', 'compute']

      // All communications inside compute subnet
      AllowAllComputeComputeIn    : ['365', 'Inbound', 'Allow', 'Tcp', 'All', 'subnet', 'compute', 'subnet', 'compute']
    
      // Scheduler
      AllowSchedIn                : ['369', 'Inbound', 'Allow', '*', 'Shed', 'asg', 'asg-sched', 'asg', 'asg-sched']
//      AllowPbsClientIn            : ['370', 'Inbound', 'Allow', '*', 'Pbs', 'asg', 'asg-pbs-client', 'asg', 'asg-pbs']
      AllowSchedComputeIn         : ['380', 'Inbound', 'Allow', '*', 'Shed', 'asg', 'asg-sched', 'subnet', 'compute']
//      AllowComputePbsClientIn     : ['390', 'Inbound', 'Allow', '*', 'Pbs', 'subnet', 'compute', 'asg', 'asg-pbs-client']
      AllowComputeSchedIn         : ['400', 'Inbound', 'Allow', '*', 'Shed', 'subnet', 'compute', 'asg', 'asg-sched']
//      AllowComputeComputeSchedIn  : ['401', 'Inbound', 'Allow', '*', 'Shed', 'subnet', 'compute', 'subnet', 'compute']
      
      // CycleCloud
      AllowCycleClientIn          : ['450', 'Inbound', 'Allow', 'Tcp', 'CycleCloud', 'asg', 'asg-cyclecloud-client', 'asg', 'asg-cyclecloud']
      AllowCycleClientComputeIn   : ['460', 'Inbound', 'Allow', 'Tcp', 'CycleCloud', 'subnet', 'compute', 'asg', 'asg-cyclecloud']
      AllowCycleServerIn          : ['465', 'Inbound', 'Allow', 'Tcp', 'CycleCloud', 'asg', 'asg-cyclecloud', 'asg', 'asg-cyclecloud-client']
    
      // Deny all remaining traffic
      DenyVnetInbound             : ['3100', 'Inbound', 'Deny', '*', 'All', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']
      
      //
      // Outbound
      //
       
      // CycleCloud
      AllowCycleServerOut         : ['300', 'Outbound', 'Allow', 'Tcp', 'CycleCloud', 'asg', 'asg-cyclecloud', 'asg', 'asg-cyclecloud-client']
      AllowCycleClientOut         : ['310', 'Outbound', 'Allow', 'Tcp', 'CycleCloud', 'asg', 'asg-cyclecloud-client', 'asg', 'asg-cyclecloud']
      AllowComputeCycleClientIn   : ['320', 'Outbound', 'Allow', 'Tcp', 'CycleCloud', 'subnet', 'compute', 'asg', 'asg-cyclecloud']
    
      // Scheduler
      AllowSchedOut               : ['340', 'Outbound', 'Allow', '*', 'Shed', 'asg', 'asg-sched', 'asg', 'asg-sched']
//      AllowPbsClientOut           : ['350', 'Outbound', 'Allow', '*', 'Pbs', 'asg', 'asg-pbs-client', 'asg', 'asg-pbs']
      AllowSchedComputeOut        : ['360', 'Outbound', 'Allow', '*', 'Shed', 'asg', 'asg-sched', 'subnet', 'compute']
      AllowComputeSchedOut        : ['370', 'Outbound', 'Allow', '*', 'Shed', 'subnet', 'compute', 'asg', 'asg-sched']
      //AllowComputePbsClientOut    : ['380', 'Outbound', 'Allow', '*', 'Pbs', 'subnet', 'compute', 'asg', 'asg-pbs-client']
//      AllowComputeComputeSchedOut : ['381', 'Outbound', 'Allow', '*', 'Shed', 'subnet', 'compute', 'subnet', 'compute']
    
      // SSH internal rules
      AllowSshFromJumpboxOut      : ['490', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-jumpbox', 'asg', 'asg-ssh']
      AllowSshComputeOut          : ['500', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-ssh', 'subnet', 'compute']
      AllowSshFromComputeOut      : ['530', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'subnet', 'compute', 'asg', 'asg-ssh']

      // All communications inside compute subnet
      AllowAllComputeComputeOut   : ['540', 'Outbound', 'Allow', 'Tcp', 'All', 'subnet', 'compute', 'subnet', 'compute']
        
      // Admin and Deployment
      AllowDnsOut                 : ['590', 'Outbound', 'Allow', '*', 'Dns', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']
     
      // Deny all remaining traffic and allow Internet access
      AllowInternetOutBound       : ['3000', 'Outbound', 'Allow', 'Tcp', 'All', 'tag', 'VirtualNetwork', 'tag', 'Internet']
      DenyVnetOutbound            : ['3100', 'Outbound', 'Deny', '*', 'All', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']
    }
    internet: {
      AllowInternetSshIn          : ['200', 'Inbound', 'Allow', 'Tcp', 'HubSsh', 'tag', 'Internet', 'asg', 'asg-jumpbox']
      AllowInternetHttpIn         : ['210', 'Inbound', 'Allow', 'Tcp', 'Web', 'tag', 'Internet', 'subnet', 'frontend']
    }
    hub: {
      AllowHubSshIn               : ['200', 'Inbound', 'Allow', 'Tcp', 'HubSsh', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']
      AllowHubHttpIn              : ['210', 'Inbound', 'Allow', 'Tcp', 'Web', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']
    }
    ad: {
      // Inbound
      // AD communication
      AllowAdServerTcpIn          : ['220', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'asg', 'asg-ad-client']
      AllowAdServerUdpIn          : ['230', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'asg', 'asg-ad-client']
      AllowAdClientTcpIn          : ['240', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad-client', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientUdpIn          : ['250', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad-client', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdServerComputeTcpIn   : ['260', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'compute']
      AllowAdServerComputeUdpIn   : ['270', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'compute']
      AllowAdClientComputeTcpIn   : ['280', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet', 'compute', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientComputeUdpIn   : ['290', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet', 'compute', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowWinRMIn                : ['520', 'Inbound', 'Allow', 'Tcp', 'WinRM', 'asg', 'asg-jumpbox', 'asg', 'asg-rdp']
      AllowRdpIn                  : ['550', 'Inbound', 'Allow', 'Tcp', 'Rdp', 'asg', 'asg-jumpbox', 'asg', 'asg-rdp']
      // Outbound
      // AD communication
      AllowAdClientTcpOut         : ['200', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad-client', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientUdpOut         : ['210', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad-client', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientComputeTcpOut  : ['220', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet', 'compute', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientComputeUdpOut  : ['230', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet', 'compute', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdServerTcpOut         : ['240', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'asg', 'asg-ad-client']
      AllowAdServerUdpOut         : ['250', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'asg', 'asg-ad-client']
      AllowAdServerComputeTcpOut  : ['260', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'compute']
      AllowAdServerComputeUdpOut  : ['270', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'compute']
      AllowRdpOut                 : ['570', 'Outbound', 'Allow', 'Tcp', 'Rdp', 'asg', 'asg-jumpbox', 'asg', 'asg-rdp']
      AllowWinRMOut               : ['580', 'Outbound', 'Allow', 'Tcp', 'WinRM', 'asg', 'asg-jumpbox', 'asg', 'asg-rdp']
    }
    ondemand: {
      // Inbound
      //AllowComputeSlurmIn         : ['405', 'Inbound', 'Allow', '*', 'Slurmd', 'asg', 'asg-ondemand', 'subnet', 'compute']
      AllowCycleWebIn             : ['440', 'Inbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-ondemand', 'asg', 'asg-cyclecloud']
      AllowComputeNoVncIn         : ['470', 'Inbound', 'Allow', 'Tcp', 'NoVnc', 'subnet', 'compute', 'asg', 'asg-ondemand']
      AllowNoVncComputeIn         : ['480', 'Inbound', 'Allow', 'Tcp', 'NoVnc', 'asg', 'asg-ondemand', 'subnet', 'compute']
      // Not sure if this is really needed. Why opening web port from deployer to ondemand ?
      // AllowWebDeployerIn          : ['595', 'Inbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-deployer', 'asg', 'asg-ondemand']
      // Outbound
      AllowCycleWebOut            : ['330', 'Outbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-ondemand', 'asg', 'asg-cyclecloud']
      //AllowSlurmComputeOut        : ['385', 'Outbound', 'Allow', '*', 'Slurmd', 'asg', 'asg-ondemand', 'subnet', 'compute']
      AllowComputeNoVncOut        : ['550', 'Outbound', 'Allow', 'Tcp', 'NoVnc', 'subnet', 'compute', 'asg', 'asg-ondemand']
      AllowNoVncComputeOut        : ['560', 'Outbound', 'Allow', 'Tcp', 'NoVnc', 'asg', 'asg-ondemand', 'subnet', 'compute']
      // AllowWebDeployerOut         : ['595', 'Outbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-deployer', 'asg', 'asg-ondemand']
    }
    mysql: {
      // Inbound
      AllowMySQLIn              : ['700', 'Inbound', 'Allow', 'Tcp', 'MySQL', 'asg', 'asg-mysql-client', 'subnet', 'database']
      // Outbound
      AllowMySQLOut             : ['700', 'Outbound', 'Allow', 'Tcp', 'MySQL', 'asg', 'asg-mysql-client', 'subnet', 'database']
    }
    anf: {
      // Inbound
      AllowNfsIn                  : ['434', 'Inbound', 'Allow', '*', 'Nfs', 'asg', 'asg-nfs-client', 'subnet', 'netapp']
      AllowNfsComputeIn           : ['435', 'Inbound', 'Allow', '*', 'Nfs', 'subnet', 'compute', 'subnet', 'netapp']
      // Outbound
      AllowNfsOut                 : ['440', 'Outbound', 'Allow', '*', 'Nfs', 'asg', 'asg-nfs-client', 'subnet', 'netapp']
      AllowNfsComputeOut          : ['450', 'Outbound', 'Allow', '*', 'Nfs', 'subnet', 'compute', 'subnet', 'netapp']
    }
    ad_anf: {
      // Inbound
      AllowAdServerNetappTcpIn    : ['300', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet', 'netapp', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdServerNetappUdpIn    : ['310', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet', 'netapp', nsgTargetForDC.type, nsgTargetForDC.target]
      // Outbound
      AllowAdServerNetappTcpOut   : ['280', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'netapp']
      AllowAdServerNetappUdpOut   : ['290', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'netapp']
    }
    lustre: {
      // Inbound
      AllowLustreClientIn         : ['410', 'Inbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre-client', 'subnet', 'lustre']
      AllowLustreClientComputeIn  : ['420', 'Inbound', 'Allow', 'Tcp', 'Lustre', 'subnet', 'compute', 'subnet', 'lustre']
      AllowLustreSubnetAnyInbound : ['430', 'Inbound', 'Allow', '*', 'All', 'subnet', 'lustre', 'subnet', 'lustre']
      // Outbound
      AllowAzureCloudServiceAccess: ['400', 'Outbound', 'Allow', '*', 'All', 'tag', 'VirtualNetwork', 'tag', 'AzureCloud']
      AllowLustreClientOut        : ['410', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre-client', 'subnet', 'lustre']
      AllowLustreClientComputeOut : ['420', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'subnet', 'compute', 'subnet', 'lustre']
      AllowLustreSubnetAnyOutbound: ['430', 'Outbound', 'Allow', '*', 'All', 'subnet', 'lustre', 'subnet', 'lustre']
    }
    bastion: {
      AllowBastionIn              : ['530', 'Inbound' , 'Allow', 'Tcp', 'Bastion', 'subnet', 'bastion', 'tag', 'VirtualNetwork']
      AllowBastionOut             : ['531', 'Outbound', 'Allow', 'Tcp', 'Bastion', 'subnet', 'bastion', 'tag', 'VirtualNetwork']
    }
    gateway: {
      AllowInternalWebUsersIn     : ['540', 'Inbound', 'Allow', 'Tcp', 'Web', 'subnet', 'gateway', 'asg', 'asg-ondemand']
    }
    grafana: {
      // Telegraf / Grafana
      // Inbound
      AllowTelegrafIn             : ['490', 'Inbound', 'Allow', 'Tcp', 'Telegraf', 'asg', 'asg-telegraf', 'asg', 'asg-grafana']
      AllowComputeTelegrafIn      : ['500', 'Inbound', 'Allow', 'Tcp', 'Telegraf', 'subnet', 'compute', 'asg', 'asg-grafana']
      AllowGrafanaIn              : ['510', 'Inbound', 'Allow', 'Tcp', 'Grafana', 'asg', 'asg-ondemand', 'asg', 'asg-grafana']
      // Outbound
      AllowTelegrafOut            : ['460', 'Outbound', 'Allow', 'Tcp', 'Telegraf', 'asg', 'asg-telegraf', 'asg', 'asg-grafana']
      AllowComputeTelegrafOut     : ['470', 'Outbound', 'Allow', 'Tcp', 'Telegraf', 'subnet', 'compute', 'asg', 'asg-grafana']
      AllowGrafanaOut             : ['480', 'Outbound', 'Allow', 'Tcp', 'Grafana', 'asg', 'asg-ondemand', 'asg', 'asg-grafana']
    }
    deployer: {
      // Inbound
      AllowSshFromDeployerIn      : ['340', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-deployer', 'asg', 'asg-ssh'] 
      AllowDeployerToPackerSshIn  : ['350', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-deployer', 'subnet', 'admin']
      // Outbound
      AllowSshDeployerOut         : ['510', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-deployer', 'asg', 'asg-ssh']
      AllowSshDeployerPackerOut   : ['520', 'Outbound', 'Allow', 'Tcp', 'Ssh', 'asg', 'asg-deployer', 'subnet', 'admin']
    }
  }
}

var vmItems = items(config.vms)

module azhopSecrets './secrets.bicep' = if (autogenerateSecrets) {
  name: 'azhopSecrets'
  params: {
    location: location
    kvName: autogenerateSecrets ? azhopKeyvault.outputs.keyvaultName : 'foo' // trick to avoid unreferenced resource for azhopKeyvaultSecrets
    adminUser: config.admin_user
    dbAdminUser: config.slurm.admin_user
    identityId: autogenerateSecrets ? identity.id : '' // trick to avoid unreferenced resource for identity
  }
}

resource kv 'Microsoft.KeyVault/vaults@2022-11-01' existing = if (autogenerateSecrets) {
  name: azhopKeyvault.outputs.keyvaultName
}

module natgateway './natgateway.bicep' = if (config.nat_gateway.create) {
  name: 'natgateway'
  params: {
    location: location
    name: config.nat_gateway.name
  }
}

var natGatewayId = config.nat_gateway.create ? natgateway.outputs.NATGatewayId : ''
var nsgRules = items(union(
  config.nsg_rules.default,
  (userAuth == 'ad') ? config.nsg_rules.ad : {},
  (userAuth == 'ad') && config.anf.create ? config.nsg_rules.ad_anf : {},
  config.public_ip ? config.nsg_rules.internet : config.nsg_rules.hub,
  config.deploy_bastion ? config.nsg_rules.bastion : {},
  config.deploy_gateway ? config.nsg_rules.gateway : {},
  config.anf.create ? config.nsg_rules.anf : {},
  config.deploy_lustre ? config.nsg_rules.lustre : {},
  config.deploy_grafana ? config.nsg_rules.grafana : {},
  config.deploy_ondemand ? config.nsg_rules.ondemand: {},
  createDatabase ? config.nsg_rules.mysql: {},
  deployDeployer ? config.nsg_rules.deployer: {}
))

module azhopNetwork './network.bicep' = {
  name: 'azhopNetwork'
  params: {
    location: location
    vnet: config.vnet
    asgNames: config.asg_names
    servicePorts: config.service_ports
    nsgRules: nsgRules
    peerings: config.vnet.peerings
    natGatewayId: natGatewayId
  }
}

output vnetId string = azhopNetwork.outputs.vnetId

var subnetIds = azhopNetwork.outputs.subnetIds
var asgNameToIdLookup = reduce(azhopNetwork.outputs.asgIds, {}, (cur, next) => union(cur, next))


module azhopBastion './bastion.bicep' = if (config.deploy_bastion) {
  name: 'azhopBastion'
  params: {
    location: location
    subnetId: subnetIds.bastion
  }
}

module azhopVm './vm.bicep' = [ for vm in vmItems: {
  name: 'azhopVm${vm.key}'
  params: {
    location: location
    name: contains(vm.value, 'name') ? vm.value.name : vm.key
    vm: vm.value
    image: config.images[vm.value.image]
    subnetId: subnetIds[vm.value.subnet]
    adminUser: config.admin_user
    adminPassword: autogenerateSecrets ? kv.getSecret(azhopSecrets.outputs.secrets.adminPassword) : adminPassword
    adminSshPublicKey: autogenerateSecrets ? kv.getSecret(azhopSecrets.outputs.secrets.adminSshPublicKey) : adminSshPublicKey
    asgIds: asgNameToIdLookup
  }
}]

// Assign roles to VMs for which roles have been specified
module azhopRoleAssignements './roleAssignments.bicep' = [ for vm in vmItems: if (contains(vm.value, 'identity') && contains(vm.value.identity, 'roles')) {
  name: 'azhopRoleFor${vm.key}'
  params: {
    name: vm.key
    roles: vm.value.identity.roles
    principalId: azhopVm[indexOf(map(vmItems, item => item.key), vm.key)].outputs.principalId
  }
}]

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (autogenerateSecrets) {
  name: 'deployScriptIdentity'
  location: location
}

resource computemi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if(createComputeMI) {
  name: computeMIname
  location: location
}

module kvAccessPoliciesSecrets './kv_access_policies.bicep' = if (autogenerateSecrets) {
  name: 'kvAccessPoliciesSecrets'
  params: {
    vaultName: autogenerateSecrets ? azhopKeyvault.outputs.keyvaultName : 'foo' // trick to avoid unreferenced resource for azhopKeyvaultSecrets
    secret_permissions: ['Set']
    principalId: autogenerateSecrets ? identity.properties.principalId : ''
  }
}

module azhopKeyvault './keyvault.bicep' = {
  name: 'azhopKeyvault'
  params: {
    location: location
    kvName: config.key_vault_name
    subnetId: subnetIds.admin
    keyvaultReaderOids: config.keyvault_readers
    lockDownNetwork: config.lock_down_network.enforce
    allowableIps: config.lock_down_network.grant_access_from
    keyvaultOwnerId: loggedUserObjectId
  }
}

module kvAccessPolicies './kv_access_policies.bicep' = [ for vm in vmItems: if (contains(vm.value, 'identity') && contains(vm.value.identity, 'keyvault')) {
  name: 'kvAccessPolicies${vm.key}'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    secret_permissions: contains(vm.value.identity.keyvault, 'secret_permissions') ? vm.value.identity.keyvault.secret_permissions : []
    principalId: azhopVm[indexOf(map(vmItems, item => item.key), vm.key)].outputs.principalId
  }
}]


module kvSecretAdminPassword './kv_secrets.bicep' = if (!autogenerateSecrets) {
  name: 'kvSecrets-admin-password'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.admin_user}-password'
    value: adminPassword
  }
}

module kvSecretAdminPubKey './kv_secrets.bicep' = if (!autogenerateSecrets)  {
  name: 'kvSecrets-admin-pubkey'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.admin_user}-pubkey'
    value: adminSshPublicKey
  }
}

module kvSecretAdminPrivKey './kv_secrets.bicep' = if (!autogenerateSecrets)  {
  name: 'kvSecrets-admin-privkey'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.admin_user}-privkey'
    value: adminSshPrivateKey
  }
}

module kvSecretDBPassword './kv_secrets.bicep' = if (!autogenerateSecrets && createDatabase) {
  name: 'kvSecrets-db-password'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.slurm.admin_user}-password'
    value: databaseAdminPassword
  }
}

// Domain join password when deploying AD will be stored in the keyvault
module kvSecretDomainJoin './kv_secrets.bicep' = if (createAD) {
  name: 'kvSecrets-domain-join'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.domain.domain_join_user.username}-password'
    value: autogenerateSecrets ? kv.getSecret(azhopSecrets.outputs.secrets.adminPassword) : adminPassword
  }
}

// Domain join password when using an existing AD will be retrieved from the keyvault specified in config and stored in our KV
resource domainJoinUserKV 'Microsoft.KeyVault/vaults@2021-10-01' existing = if (useExistingAD) {
  name: '${config.domain.domain_join_user.password_key_vault_name}'
  scope: resourceGroup(config.domain.domain_join_user.password_key_vault_resource_group_name)
}
module kvSecretExistingDomainJoin './kv_secrets.bicep' = if (useExistingAD) {
  name: 'kvSecrets-existing-domain-join'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.domain.domain_join_user.username}-password'
    value: domainJoinUserKV.getSecret(config.domain.domain_join_user.password_key_vault_secret_name)
  }
}

module azhopStorage './storage.bicep' = {
  name: 'azhopStorage'
  params:{
    location: location
    saName: config.storage_account_name
    lockDownNetwork: config.lock_down_network.enforce
    allowableIps: config.lock_down_network.grant_access_from
    subnetIds: [ subnetIds.admin, subnetIds.compute ]
  }
}

module azhopSig './sig.bicep' = if (config.deploy_sig) {
  name: 'azhopSig'
  params: {
    location: location
    resourcePostfix: resourcePostfix
  }
}

// module azhopMariaDB './mariadb.bicep' = if (createDatabase) {
//   name: 'azhopMariaDB'
//   params: {
//     location: location
//     mariaDbName: config.mariadb_name
//     adminUser: config.slurm.admin_user
//     adminPassword: autogenerateSecrets ? kv.getSecret(azhopSecrets.outputs.secrets.databaseAdminPassword) : databaseAdminPassword
//     adminSubnetId: subnetIds.admin
//     vnetId: azhopNetwork.outputs.vnetId
//     sslEnforcement: true
//   }
// }

module mySQL './mysql.bicep' = if (createDatabase) {
  name: 'mySQLDB'
  params: {
    location: location
    Name: config.db_name
    adminUser: config.slurm.admin_user
    adminPassword: autogenerateSecrets ? kv.getSecret(azhopSecrets.outputs.secrets.databaseAdminPassword) : databaseAdminPassword
    subnetId: subnetIds.database
  }
}

module azhopTelemetry './telemetry.bicep' = {
  name: 'azhopTelemetry'
}

module azhopVpnGateway './vpngateway.bicep' = if (config.deploy_gateway) {
  name: 'azhopVpnGateway'
  params: {
    location: location
    subnetId: subnetIds.gateway
  }
}

module azhopAmlfs './amlfs.bicep' = if (deployLustre) {
  name: 'azhopAmlfs'
  params: {
    location: location
    name: 'amlfs${resourcePostfix}'
    subnetId: subnetIds.lustre
    sku: config.lustre.sku
    capacity: config.lustre.capacity
  }
}

module azhopAnf './anf.bicep' = if (config.anf.create) {
  name: 'azhopAnf'
  params: {
    location: location
    resourcePostfix: resourcePostfix
    dualProtocol: config.anf.dual_protocol
    subnetId: subnetIds.netapp
    adUser: config.admin_user
    adPassword: autogenerateSecrets ? kv.getSecret(azhopSecrets.outputs.secrets.adminPassword) : adminPassword
    adDns: adIp
    serviceLevel: config.anf.service_level
    sizeGB: config.anf.size_gb
  }
}

module azhopNfsFiles './nfsfiles.bicep' = if (config.azurefiles.create ) {
  name: 'azhopNfsFiles'
  params: {
    location: location
    resourcePostfix: resourcePostfix
    allowedSubnetIds: [ subnetIds.admin, subnetIds.compute, subnetIds.frontend ]
    sizeGB: config.azurefiles.size_gb
  }
}

module azhopPrivateZone './privatezone.bicep' = if (createAD || useExistingAD || config.private_dns.create) {
  name: 'azhopPrivateZone'
  params: {
    privateDnsZoneName: config.domain.name
    vnetId: azhopNetwork.outputs.vnetId
    registrationEnabled: config.private_dns.registration_enabled
  }
}

// list of DC VMs. The first one will be considered the default PDC (for DNS registration)
// Trick to get the index of the DC VM in the vmItems array, to workaround a bug in bicep 0.14.85 as it throws an error when using indexOf(map(vmItems, item => item.key), 'ad2')
var adIndex = createAD ? indexOf(map(vmItems, item => item.key), 'ad') : 0
var adIp = createAD ? azhopVm[adIndex].outputs.privateIp : ''
var ad2Index = createAD && highAvailabilityForAD ? indexOf(map(vmItems, item => item.key), 'ad2') : 0
var ad2Ip = createAD ? azhopVm[ad2Index].outputs.privateIp : ''
var domain_controller_ip_addresses = useExistingAD && contains(azhopConfig, 'domain') && contains(azhopConfig.domain, 'existing_dc_details') ? azhopConfig.domain.existing_dc_details.domain_controller_ip_addresses : []
var dcIps = createAD ? (! highAvailabilityForAD ? [adIp] : [adIp, ad2Ip]) : domain_controller_ip_addresses
module azhopADRecords './privatezone_records.bicep' = if (createAD || useExistingAD) {
  name: 'azhopADRecords'
  params: {
    privateDnsZoneName: config.domain.name
    adVmNames: config.domain.domain_controlers
    adVmIps: dcIps
  }
}

output ccportalPrincipalId string = azhopVm[indexOf(map(vmItems, item => item.key), 'ccportal')].outputs.principalId

output keyvaultName string = azhopKeyvault.outputs.keyvaultName

// Our input file is also the deployment output
output azhopConfig object = azhopConfig

var envNameToCloudMap = {
  AzureCloud: 'AZUREPUBLICCLOUD'
  AzureUSGovernment: 'AZUREUSGOVERNMENT'
  AzureGermanCloud: 'AZUREGERMANCLOUD'
  AzureChinaCloud: 'AZURECHINACLOUD'
}

var kvSuffix = environment().suffixes.keyvaultDns

output azhopGlobalConfig object = union(
  {
    global_cc_storage             : config.storage_account_name
    compute_subnetid              : '${azhopResourceGroupName}/${config.vnet.name}/${config.vnet.subnets.compute.name}'
    global_config_file            : '/az-hop/config.yml'
    ad_join_user                  : config.domain.domain_join_user.username
    domain_name                   : config.domain.name
    ldap_server                   : '${config.domain.ldap_server}.${config.domain.name}'
    homedir_mountpoint            : config.homedir_mountpoint
    ondemand_fqdn                 : deployOnDemand ? (config.public_ip ? azhopVm[indexOf(map(vmItems, item => item.key), 'ondemand')].outputs.fqdn : azhopVm[indexOf(map(vmItems, item => item.key), 'ondemand')].outputs.privateIp) : ''
    ansible_ssh_private_key_file  : '${config.admin_user}_id_rsa'
    subscription_id               : subscription().subscriptionId
    tenant_id                     : subscription().tenantId
    key_vault                     : config.key_vault_name
    sig_name                      : (config.deploy_sig) ? 'azhop_${resourcePostfix}' : ''
    lustre_hsm_storage_account    : config.storage_account_name
    lustre_hsm_storage_container  : 'lustre'
    database_fqdn                 : createDatabase ? mySQL.outputs.fqdn : ''
    database_user                 : config.slurm.admin_user
    azure_environment             : envNameToCloudMap[environment().name]
    key_vault_suffix              : substring(kvSuffix, 1, length(kvSuffix) - 1) // vault.azure.net - remove leading dot from env
    blob_storage_suffix           : 'blob.${environment().suffixes.storage}' // blob.core.windows.net
    jumpbox_ssh_port              : incomingSSHPort
  },
  createComputeMI ? {
    compute_mi_id                 : resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', computemi.name)
  }: {},
  !empty(existingComputeMIrg) ? {
    compute_mi_id                 : resourceId(existingComputeMIrg,'Microsoft.ManagedIdentity/userAssignedIdentities', computeMIname)
  }: {},
  config.homedir_type == 'anf' ? {
    anf_home_ip                   : azhopAnf.outputs.nfs_home_ip
    anf_home_path                 : azhopAnf.outputs.nfs_home_path
    anf_home_opts                 : azhopAnf.outputs.nfs_home_opts
  } : {},
  config.homedir_type == 'azurefiles' ? {
    anf_home_ip                   : azhopNfsFiles.outputs.nfs_home_ip
    anf_home_path                 : azhopNfsFiles.outputs.nfs_home_path
    anf_home_opts                 : azhopNfsFiles.outputs.nfs_home_opts
  } : {},
  config.homedir_type == 'existing' ? {
    anf_home_ip                   : azhopConfig.mounts.home.server
    anf_home_path                 : azhopConfig.mounts.home.export
    anf_home_opts                 : azhopConfig.mounts.home.options
  } : {},
  deployLustre ? {
    lustre_mgs                    : azhopAmlfs.outputs.lustre_mgs
  } : {}
)

var sshTunelIp = deployJumpbox ? ( config.public_ip ? azhopVm[indexOf(map(vmItems, item => item.key), 'jumpbox')].outputs.publicIp : azhopVm[indexOf(map(vmItems, item => item.key), 'jumpbox')].outputs.privateIp ) : ''

output azhopInventory object = {
  all: {
    hosts: union (
      {
        localhost: {
          psrp_ssh_proxy: sshTunelIp
        }
        scheduler: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'scheduler')].outputs.privateIp
        }
        ccportal: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'ccportal')].outputs.privateIp
        }
      },
      config.deploy_ondemand ? {
        ondemand: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'ondemand')].outputs.privateIp
        }
      } : {},
      indexOf(map(vmItems, item => item.key), 'ad') >= 0 ? {
        ad: {
        ansible_host: adIp
        ansible_connection: 'psrp'
        ansible_psrp_protocol: 'http'
        ansible_user: config.admin_user
        ansible_password: '__ADMIN_PASSWORD__'
        psrp_ssh_proxy: sshTunelIp
        ansible_psrp_proxy: deployJumpbox ? 'socks5h://localhost:5985' : ''
        }
      } : {} ,
      indexOf(map(vmItems, item => item.key), 'ad2') >= 0 ? {
        ad2: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'ad2')].outputs.privateIp
          ansible_connection: 'psrp'
          ansible_psrp_protocol: 'http'
          ansible_user: config.admin_user
          ansible_password: '__ADMIN_PASSWORD__'
          psrp_ssh_proxy: sshTunelIp
          ansible_psrp_proxy: deployJumpbox ? 'socks5h://localhost:5985' : ''
        }
      } : {} ,
      deployJumpbox ? {
        jumpbox : {
          ansible_host: sshTunelIp
          ansible_ssh_port: incomingSSHPort
          ansible_ssh_common_args: ''
        }
      } : {},
      deployDeployer ? {
        deployer : {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'deployer')].outputs.privateIp
          ansible_ssh_port: incomingSSHPort
          ansible_ssh_common_args: ''
        }
      } : {},
      config.deploy_grafana ? {
        grafana: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'grafana')].outputs.privateIp
        }
      } : {}
    )
    vars: {
      ansible_ssh_user: config.admin_user
      ansible_ssh_common_args: deployJumpbox ? '-o ProxyCommand="ssh -i ${config.admin_user}_id_rsa -p ${incomingSSHPort} -W %h:%p ${config.admin_user}@${sshTunelIp}"' : ''

    }
  }
}

output azhopPackerOptions object = (config.deploy_sig) ? {
  var_subscription_id: subscription().subscriptionId
  var_resource_group: azhopResourceGroupName
  var_location: location
  var_sig_name: 'azhop_${resourcePostfix}'
  var_private_virtual_network_with_public_ip: 'false'
  var_virtual_network_name: config.vnet.name
  var_virtual_network_subnet_name: config.vnet.subnets.compute.name
  var_virtual_network_resource_group_name: azhopResourceGroupName
  var_ssh_bastion_host: sshTunelIp
  var_ssh_bastion_port: incomingSSHPort
  var_ssh_bastion_username: config.admin_user
  var_ssh_bastion_private_key_file: '../${config.admin_user}_id_rsa'
  var_queue_manager: config.queue_manager
} : {}

var azhopConnectScript = format('''
#!/bin/bash

exec ssh -i {0}_id_rsa  "$@"

''', config.admin_user)

var azhopSSHConnectScript = format('''
#!/bin/bash
case $1 in
  cyclecloud)
    echo go create tunnel to cyclecloud at https://localhost:9443/cyclecloud
    ssh -i {0}_id_rsa -fN -L 9443:ccportal:9443 -p {1} {0}@{2}
    ;;
  ad)
    echo go create tunnel to ad with rdp to localhost:3390
    ssh -i {0}_id_rsa -fN -L 3390:ad:3389 -p {1} {0}@{2}
    ;;
  deployer|jumpbox)
    ssh -i {0}_id_rsa -p {1} {0}@{2}
    ;;
  *)
    exec ssh -i {0}_id_rsa -o ProxyCommand="ssh -i {0}_id_rsa -p {1} -W %h:%p {0}@{2}" -o "User={0}" "$@"
    ;;
esac
''', config.admin_user, incomingSSHPort, sshTunelIp)

output azhopConnectScript string = deployDeployer ? azhopConnectScript : azhopSSHConnectScript


output azhopGetSecretScript string = format('''
#!/bin/bash

user=$1
# Because secret names are restricted to '^[0-9a-zA-Z-]+$' we need to remove all other characters
secret_name=$(echo $user-password | tr -dc 'a-zA-Z0-9-')

az keyvault secret show --vault-name {0} -n $secret_name --query "value" -o tsv

''', config.key_vault_name)

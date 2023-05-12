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

var deployLustre = contains(azhopConfig, 'lustre') && contains(azhopConfig.lustre, 'create') ? azhopConfig.lustre.create : false
var deployJumpbox = contains(azhopConfig, 'jumpbox') ? true : false
var deployDeployer = contains(azhopConfig, 'deployer') ? true : false
var enableWinViz = contains(azhopConfig, 'enable_remote_winviz') ? azhopConfig.enable_remote_winviz : false

var createAD = contains(azhopConfig, 'domain') ? ! azhopConfig.domain.use_existing_dc : true

var highAvailabilityForAD = contains(azhopConfig, 'ad') && contains(azhopConfig.ad, 'high_availability') ? azhopConfig.ad.high_availability : false

var linuxBaseImage = contains(azhopConfig, 'linux_base_image') ? azhopConfig.linux_base_image : 'OpenLogic:CentOS:7_9-gen2:latest'
var linuxBasePlan = contains(azhopConfig, 'linux_base_plan') ? azhopConfig.linux_base_plan : ''
var windowsBaseImage = contains(azhopConfig, 'windows_base_image') ? azhopConfig.windows_base_image : 'MicrosoftWindowsServer:WindowsServer:2019-Datacenter-smalldisk:latest'
var lustreBaseImage = contains(azhopConfig, 'lustre_base_image') ? azhopConfig.lustre_base_image : 'azhpc:azurehpc-lustre:azurehpc-lustre-2_12:latest'
var lustreBasePlan = contains(azhopConfig, 'lustre_base_plan') ? azhopConfig.lustre_base_plan : 'azhpc:azurehpc-lustre:azurehpc-lustre-2_12'

var createDatabase = (config.queue_manager == 'slurm' && config.slurm.accounting_enabled ) || config.enable_remote_winviz

var lustreOssCount = deployLustre ? azhopConfig.lustre.oss_count : 0

var ossVmConfig = [for oss in range(0, lustreOssCount) : { 
  key: 'lustre-oss-${oss}'
  value: {
    identity: {
      keyvault: {
        secret_permissions: [ 'Get', 'List' ]
      }
    }
    subnet: 'admin'
    sku: azhopConfig.lustre.oss_sku
    osdisksku: 'StandardSSD_LRS'
    image: 'lustre'
    asgs: [ 'asg-ssh', 'asg-lustre', 'asg-lustre-client', 'asg-telegraf' ]
  }
} ]

var nsgTargetForDC = {
  type: createAD ? 'asg' : 'ips'
  target: createAD ? 'asg-ad' : azhopConfig.domain.existing_dc_details.domain_controller_ip_addresses
}

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

  queue_manager: contains(azhopConfig, 'queue_manager') ? azhopConfig.queue_manager : 'openpbs'

  slurm: {
    admin_user: contains(azhopConfig, 'database') && contains(azhopConfig.database, 'user') ? azhopConfig.database.user : 'sqladmin'
    accounting_enabled: contains(azhopConfig.slurm, 'accounting_enabled') ? azhopConfig.slurm.accounting_enabled : false
  }

  domain: {
    name : contains(azhopConfig, 'domain') ? azhopConfig.domain.name : 'hpc.azure'
    domain_join_user: createAD ? {
      username: azhopConfig.admin_user
    } : {
      username: azhopConfig.domain.domain_join_user.username
      password_key_vault_name: azhopConfig.domain.domain_join_user.password_key_vault_name
      password_key_vault_resource_group_name: azhopConfig.domain.domain_join_user.password_key_vault_resource_group_name
      password_key_vault_secret_name: azhopConfig.domain.domain_join_user.password_key_vault_secret_name
    }
    domain_controlers : createAD ? (! highAvailabilityForAD ? ['ad'] : ['ad', 'ad2']) : azhopConfig.domain.existing_dc_details.domain_controller_names
    ldap_server: createAD ? 'ad' : azhopConfig.domain.existing_dc_details.domain_controller_names[0]
  }

  enable_remote_winviz : enableWinViz
  deploy_sig: contains(azhopConfig, 'image_gallery') && contains(azhopConfig.image_gallery, 'create') ? azhopConfig.image_gallery.create : false

  // Default home directory is ANF
  homedir_type: contains(azhopConfig.mounts.home, 'type') ? azhopConfig.mounts.home.type : 'existing'
  homedir_mountpoint: azhopConfig.mounts.home.mountpoint

  anf: {
    create: contains(azhopConfig, 'anf') && contains(azhopConfig.anf, 'create') ? azhopConfig.anf.create : (contains(azhopConfig, 'anf') ? true : false)
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
        service_endpoints: [
          'Microsoft.Storage'
        ]
      }
      admin: {
        name: contains(azhopConfig.network.vnet.subnets.admin, 'name') ? azhopConfig.network.vnet.subnets.admin.name : 'admin'
        cidr: azhopConfig.network.vnet.subnets.admin.address_prefixes
        service_endpoints: [
          'Microsoft.KeyVault'
          'Microsoft.Storage'
        ]
      }
      netapp: {
        apply_nsg: false
        name: contains(azhopConfig.network.vnet.subnets.netapp, 'name') ? azhopConfig.network.vnet.subnets.netapp.name : 'netapp'
        cidr: azhopConfig.network.vnet.subnets.netapp.address_prefixes
        delegations: [
          'Microsoft.Netapp/volumes'
        ]
      }
      compute: {
        name: contains(azhopConfig.network.vnet.subnets.compute, 'name') ? azhopConfig.network.vnet.subnets.compute.name : 'compute'
        cidr: azhopConfig.network.vnet.subnets.compute.address_prefixes
        service_endpoints: [
          'Microsoft.Storage'
        ]
      }
    },
    createAD ? {
      ad: {
        name: contains(azhopConfig.network.vnet.subnets.ad, 'name') ? azhopConfig.network.vnet.subnets.ad.name : 'ad'
        cidr: azhopConfig.network.vnet.subnets.ad.address_prefixes
      }
    } : {},
    contains(azhopConfig.network.vnet.subnets,'bastion') ? {
      bastion: {
        apply_nsg: false
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
    lustre: {
      plan: lustreBasePlan
      ref: {
        publisher: split(lustreBaseImage,':')[0]
        offer: split(lustreBaseImage,':')[1]
        sku: split(lustreBaseImage,':')[2]
        version: split(lustreBaseImage,':')[3]
      }
    }
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
  }


  vms: union(
    {
      ondemand: {
        subnet: 'frontend'
        sku: azhopConfig.ondemand.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        pip: enablePublicIP
        asgs: union(
          [ 'asg-ssh', 'asg-ondemand', 'asg-ad-client', 'asg-nfs-client', 'asg-pbs-client', 'asg-telegraf', 'asg-guacamole', 'asg-cyclecloud-client', 'asg-mariadb-client' ],
          deployLustre ? [ 'asg-lustre-client' ] : []
        )
      }
      grafana: {
        subnet: 'admin'
        sku: azhopConfig.grafana.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        asgs: [ 'asg-ssh', 'asg-grafana', 'asg-ad-client', 'asg-telegraf', 'asg-nfs-client' ]
      }
      ccportal: {
        subnet: 'admin'
        sku: azhopConfig.cyclecloud.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        datadisks: [
          {
            name: 'ccportal-datadisk0'
            disksku: 'Premium_LRS'
            size: 128
            caching: 'ReadWrite'
          }
        ]
        identity: {
          roles: [
            'Contributor'
          ]
        }
        asgs: [ 'asg-ssh', 'asg-cyclecloud', 'asg-telegraf', 'asg-ad-client' ]
      }
      scheduler: {
        subnet: 'admin'
        sku: azhopConfig.scheduler.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        asgs: [ 'asg-ssh', 'asg-pbs', 'asg-ad-client', 'asg-cyclecloud-client', 'asg-nfs-client', 'asg-telegraf', 'asg-mariadb-client' ]
      }
    },
    createAD ? {
      ad: {
        subnet: 'ad'
        windows: true
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
          sku: azhopConfig.deployer.vm_size
          osdisksku: 'Standard_LRS'
          image: 'ubuntu'
          pip: enablePublicIP
          sshPort: deployerSshPort
          asgs: [ 'asg-ssh', 'asg-jumpbox', 'asg-deployer', 'asg-telegraf' ]
          deploy_script: replace(replace(loadTextContent('install.sh'), '__INSERT_AZHOP_BRANCH__', branchName), '__SSH_PORT__', string(deployerSshPort))
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
        sku: azhopConfig.ad.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'win_base'
        asgs: [ 'asg-ad', 'asg-rdp', 'asg-ad-client' ]
      }
    } : {} ,
    enableWinViz ? {
      guacamole: {
      identity: {
        keyvault: {
          secret_permissions: [ 'Get', 'List' ]
        }
      }
      subnet: 'admin'
      sku: azhopConfig.guacamole.vm_size
      osdisksku: 'StandardSSD_LRS'
      image: 'linux_base'
      asgs: [ 'asg-ssh', 'asg-ad-client', 'asg-telegraf', 'asg-nfs-client', 'asg-cyclecloud-client', 'asg-mariadb-client' ]
      }
    } : {},
    deployJumpbox ? {
      jumpbox: {
        subnet: 'frontend'
        sku: azhopConfig.jumpbox.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        pip: enablePublicIP
        sshPort: jumpboxSshPort
        asgs: [ 'asg-ssh', 'asg-jumpbox', 'asg-ad-client', 'asg-telegraf', 'asg-nfs-client' ]
        deploy_script: jumpboxSshPort != 22 ? replace(loadTextContent('jumpbox.yml'), '__SSH_PORT__', string(jumpboxSshPort)) : ''
      }
    } : {},
    deployLustre ? {
      lustre: {
        subnet: 'admin'
        sku: azhopConfig.lustre.mds_sku
        osdisksku: 'StandardSSD_LRS'
        image: 'lustre'
        asgs: [ 'asg-ssh', 'asg-lustre', 'asg-lustre-client', 'asg-telegraf' ]
      }
      robinhood: {
        identity: {
          keyvault: {
            secret_permissions: [ 'Get', 'List' ]
          }
        }
        subnet: 'admin'
        sku: azhopConfig.lustre.rbh_sku
        osdisksku: 'StandardSSD_LRS'
        image: 'lustre'
        asgs: [ 'asg-ssh', 'asg-robinhood', 'asg-lustre-client', 'asg-telegraf' ]
      }
    } : {}
  )

  asg_names: union([ 'asg-ssh', 'asg-rdp', 'asg-jumpbox', 'asg-ad', 'asg-ad-client', 'asg-pbs', 'asg-pbs-client', 'asg-cyclecloud', 'asg-cyclecloud-client', 'asg-nfs-client', 'asg-telegraf', 'asg-grafana', 'asg-robinhood', 'asg-ondemand', 'asg-deployer', 'asg-guacamole', 'asg-mariadb-client' ],
    deployLustre ? [ 'asg-lustre', 'asg-lustre-client' ] : []
  )

  service_ports: {
    All: ['0-65535']
    Bastion: ['22', '3389']
    Web: ['443', '80']
    Ssh: ['22']
    HubSsh: [string(jumpboxSshPort), string(deployerSshPort)]
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
    MariaDB: ['3306', '33060']
    Guacamole: ['8080']
    WinRM: ['5985', '5986']
  }

  nsg_rules: {
      default: {
      //
      // INBOUND RULES
      //
    
      // AD communication
      AllowAdServerTcpIn          : ['220', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'asg', 'asg-ad-client']
      AllowAdServerUdpIn          : ['230', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'asg', 'asg-ad-client']
      AllowAdClientTcpIn          : ['240', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad-client', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientUdpIn          : ['250', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad-client', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdServerComputeTcpIn   : ['260', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'compute']
      AllowAdServerComputeUdpIn   : ['270', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'compute']
      AllowAdClientComputeTcpIn   : ['280', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet', 'compute', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientComputeUdpIn   : ['290', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet', 'compute', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdServerNetappTcpIn    : ['300', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet', 'netapp', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdServerNetappUdpIn    : ['310', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet', 'netapp', nsgTargetForDC.type, nsgTargetForDC.target]
    
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
    
      // MariaDB
      AllowMariaDBIn              : ['700', 'Inbound', 'Allow', 'Tcp', 'MariaDB', 'asg', 'asg-mariadb-client', 'subnet', 'admin']

      // Deny all remaining traffic
      DenyVnetInbound             : ['3100', 'Inbound', 'Deny', '*', 'All', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']
    
    
      //
      // Outbound
      //
    
      // AD communication
      AllowAdClientTcpOut         : ['200', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg', 'asg-ad-client', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientUdpOut         : ['210', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg', 'asg-ad-client', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientComputeTcpOut  : ['220', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet', 'compute', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdClientComputeUdpOut  : ['230', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet', 'compute', nsgTargetForDC.type, nsgTargetForDC.target]
      AllowAdServerTcpOut         : ['240', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'asg', 'asg-ad-client']
      AllowAdServerUdpOut         : ['250', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'asg', 'asg-ad-client']
      AllowAdServerComputeTcpOut  : ['260', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'compute']
      AllowAdServerComputeUdpOut  : ['270', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'compute']
      AllowAdServerNetappTcpOut   : ['280', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'netapp']
      AllowAdServerNetappUdpOut   : ['290', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', nsgTargetForDC.type, nsgTargetForDC.target, 'subnet', 'netapp']
    
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
      
      // MariaDB
      AllowMariaDBOut             : ['700', 'Outbound', 'Allow', 'Tcp', 'MariaDB', 'asg', 'asg-mariadb-client', 'subnet', 'admin']
      
      // Deny all remaining traffic and allow Internet access
      AllowInternetOutBound       : ['3000', 'Outbound', 'Allow', 'Tcp', 'All', 'tag', 'VirtualNetwork', 'tag', 'Internet']
      DenyVnetOutbound            : ['3100', 'Outbound', 'Deny', '*', 'All', 'tag', 'VirtualNetwork', 'tag', 'VirtualNetwork']
    }
    lustre: {
      // Inbound
      AllowLustreIn               : ['409', 'Inbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre', 'asg', 'asg-lustre-client']
      AllowLustreClientIn         : ['410', 'Inbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre-client', 'asg', 'asg-lustre']
      AllowLustreClientComputeIn  : ['420', 'Inbound', 'Allow', 'Tcp', 'Lustre', 'subnet', 'compute', 'asg', 'asg-lustre']
      AllowRobinhoodIn            : ['430', 'Inbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-ondemand', 'asg', 'asg-robinhood']
      // Outbound
      AllowLustreOut              : ['390', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre', 'asg', 'asg-lustre-client']
      AllowLustreClientOut        : ['400', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre-client', 'asg', 'asg-lustre']
      //AllowLustreComputeOut       : ['410', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'asg', 'asg-lustre', 'subnet', 'compute']
      AllowLustreClientComputeOut : ['420', 'Outbound', 'Allow', 'Tcp', 'Lustre', 'subnet', 'compute', 'asg', 'asg-lustre']
      AllowRobinhoodOut           : ['430', 'Outbound', 'Allow', 'Tcp', 'Web', 'asg', 'asg-ondemand', 'asg', 'asg-robinhood']
    }
    internet: {
      AllowInternetSshIn          : ['200', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'tag', 'Internet', 'asg', 'asg-jumpbox']
      AllowInternetHttpIn         : ['210', 'Inbound', 'Allow', 'Tcp', 'Web', 'tag', 'Internet', 'asg', 'asg-ondemand']
    }
    hub: {
      AllowHubSshIn               : ['200', 'Inbound', 'Allow', 'Tcp', 'HubSsh', 'tag', 'VirtualNetwork', 'asg', 'asg-jumpbox']
      AllowHubHttpIn              : ['210', 'Inbound', 'Allow', 'Tcp', 'Web',        'tag', 'VirtualNetwork', 'asg', 'asg-ondemand']
    }
    bastion: {
      AllowBastionIn              : ['530', 'Inbound', 'Allow', 'Tcp', 'Bastion', 'subnet', 'bastion', 'tag', 'VirtualNetwork']
    }
    gateway: {
      AllowInternalWebUsersIn     : ['540', 'Inbound', 'Allow', 'Tcp', 'Web', 'subnet', 'gateway', 'asg', 'asg-ondemand']
    }
  }
}

var vmItems = concat(items(config.vms), ossVmConfig)

module azhopSecrets './secrets.bicep' = if (autogenerateSecrets) {
  name: 'azhopSecrets'
  params: {
    location: location
  }
}

var secrets = (autogenerateSecrets) ? azhopSecrets.outputs.secrets : {
  adminSshPublicKey: adminSshPublicKey
  adminSshPrivateKey: adminSshPrivateKey
  adminPassword: adminPassword
  databaseAdminPassword: databaseAdminPassword
}

var domainPassword = secrets.adminPassword

module azhopNetwork './network.bicep' = {
  name: 'azhopNetwork'
  params: {
    location: location
    deployGateway: config.deploy_gateway
    deployBastion: config.deploy_bastion
    deployLustre: config.deploy_lustre
    publicIp: config.public_ip
    vnet: config.vnet
    asgNames: config.asg_names
    servicePorts: config.service_ports
    nsgRules: config.nsg_rules
    peerings: config.vnet.peerings
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
    name: vm.key
    vm: vm.value
    image: config.images[vm.value.image]
    subnetId: subnetIds[vm.value.subnet]
    adminUser: config.admin_user
    secrets: secrets
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

module azhopKeyvault './keyvault.bicep' = {
  name: 'azhopKeyvault'
  params: {
    location: location
    resourcePostfix: resourcePostfix
    subnetId: subnetIds.admin
    keyvaultReaderOids: config.keyvault_readers
    lockDownNetwork: config.lock_down_network.enforce
    allowableIps: config.lock_down_network.grant_access_from
    keyvaultOwnerId: loggedUserObjectId
    identityPerms: [ for i in range(0, length(vmItems)): {
      principalId: azhopVm[i].outputs.principalId
      key_permissions: (contains(vmItems[i].value, 'identity') && contains(vmItems[i].value.identity, 'keyvault') && contains(vmItems[i].value.identity.keyvault, 'key_permissions')) ? vmItems[i].value.identity.keyvault.key_permissions : []
      secret_permissions: (contains(vmItems[i].value, 'identity') && contains(vmItems[i].value.identity, 'keyvault')) ? vmItems[i].value.identity.keyvault.secret_permissions : []
    }]
  }
}

module kvSecretAdminPassword './kv_secrets.bicep' = {
  name: 'kvSecrets-admin-password'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.admin_user}-password'
    value: secrets.adminPassword
  }
}

module kvSecretAdminPubKey './kv_secrets.bicep' = {
  name: 'kvSecrets-admin-pubkey'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.admin_user}-pubkey'
    value: secrets.adminSshPublicKey
  }
}

module kvSecretAdminPrivKey './kv_secrets.bicep' = {
  name: 'kvSecrets-admin-privkey'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.admin_user}-privkey'
    value: secrets.adminSshPrivateKey
  }
}

module kvSecretDBPassword './kv_secrets.bicep' = if (createDatabase) {
  name: 'kvSecrets-db-password'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.slurm.admin_user}-password'
    value: secrets.databaseAdminPassword
  }
}

// Domain join password when deploying AD will be stored in the keyvault
module kvSecretDomainJoin './kv_secrets.bicep' = if (createAD) {
  name: 'kvSecrets-domain-join'
  params: {
    vaultName: azhopKeyvault.outputs.keyvaultName
    name: '${config.domain.domain_join_user.username}-password'
    value: domainPassword
  }
}

// Domain join password when using an existing AD will be retrieved from the keyvault specified in config and stored in our KV
resource domainJoinUserKV 'Microsoft.KeyVault/vaults@2021-10-01' existing = if (! createAD) {
  name: '${config.domain.domain_join_user.password_key_vault_name}'
  scope: resourceGroup(config.domain.domain_join_user.password_key_vault_resource_group_name)
}
module kvSecretExistingDomainJoin './kv_secrets.bicep' = if (! createAD) {
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
    resourcePostfix: resourcePostfix
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

module azhopMariaDB './mariadb.bicep' = if (createDatabase) {
  name: 'azhopMariaDB'
  params: {
    location: location
    resourcePostfix: resourcePostfix
    adminUser: config.slurm.admin_user
    adminPassword: secrets.databaseAdminPassword
    adminSubnetId: subnetIds.admin
    vnetId: azhopNetwork.outputs.vnetId
    sslEnforcement: config.enable_remote_winviz ? false : true // based whether guacamole is enabled (guac doesn't support ssl atm)
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

module azhopAnf './anf.bicep' = if (config.anf.create) {
  name: 'azhopAnf'
  params: {
    location: location
    resourcePostfix: resourcePostfix
    dualProtocol: config.anf.dual_protocol
    subnetId: subnetIds.netapp
    adUser: config.admin_user
    adPassword: secrets.adminPassword
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

module azhopPrivateZone './privatezone.bicep' = {
  name: 'azhopPrivateZone'
  params: {
    privateDnsZoneName: config.domain.name
    vnetId: azhopNetwork.outputs.vnetId
  }
}

// list of DC VMs. The first one will be considered the default PDC (for DNS registration)
// Trick to get the index of the DC VM in the vmItems array, to workaround a bug in bicep 0.14.85 as it throws an error when using indexOf(map(vmItems, item => item.key), 'ad2')
var adIndex = createAD ? indexOf(map(vmItems, item => item.key), 'ad') : 0
var adIp = createAD ? azhopVm[adIndex].outputs.privateIp : ''
var ad2Index = createAD && highAvailabilityForAD ? indexOf(map(vmItems, item => item.key), 'ad2') : 0
var ad2Ip = createAD ? azhopVm[ad2Index].outputs.privateIp : ''
var dcIps = createAD ? (! highAvailabilityForAD ? [adIp] : [adIp, ad2Ip]) : azhopConfig.domain.existing_dc_details.domain_controller_ip_addresses
module azhopADRecords './privatezone_records.bicep' = {
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
    global_cc_storage             : 'azhop${resourcePostfix}'
    compute_subnetid              : '${azhopResourceGroupName}/${config.vnet.name}/${config.vnet.subnets.compute.name}'
    global_config_file            : '/az-hop/config.yml'
    ad_join_user                  : config.domain.domain_join_user.username
    domain_name                   : config.domain.name
    ldap_server                   : config.domain.ldap_server
    homedir_mountpoint            : config.homedir_mountpoint
    ondemand_fqdn                 : config.public_ip ? azhopVm[indexOf(map(vmItems, item => item.key), 'ondemand')].outputs.fqdn : azhopVm[indexOf(map(vmItems, item => item.key), 'ondemand')].outputs.privateIp
    ansible_ssh_private_key_file  : '${config.admin_user}_id_rsa'
    subscription_id               : subscription().subscriptionId
    tenant_id                     : subscription().tenantId
    key_vault                     : 'kv${resourcePostfix}'
    sig_name                      : (config.deploy_sig) ? 'azhop_${resourcePostfix}' : ''
    lustre_hsm_storage_account    : 'azhop${resourcePostfix}'
    lustre_hsm_storage_container  : 'lustre'
    database_fqdn                 : createDatabase ? azhopMariaDB.outputs.mariaDb_fqdn : ''
    database_user                 : config.slurm.admin_user
    azure_environment             : envNameToCloudMap[environment().name]
    key_vault_suffix              : substring(kvSuffix, 1, length(kvSuffix) - 1) // vault.azure.net - remove leading dot from env
    blob_storage_suffix           : 'blob.${environment().suffixes.storage}' // blob.core.windows.net
    jumpbox_ssh_port              : deployJumpbox ? config.vms.jumpbox.sshPort : 22
  },
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
  } : {}
)

output azhopInventory object = {
  all: {
    hosts: union (
      {
        localhost: {
          psrp_ssh_proxy: deployJumpbox ? azhopVm[indexOf(map(vmItems, item => item.key), 'jumpbox')].outputs.privateIp : ''
        }
        scheduler: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'scheduler')].outputs.privateIp
        }
        ondemand: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'ondemand')].outputs.privateIp
        }
        ccportal: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'ccportal')].outputs.privateIp
        }
        grafana: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'grafana')].outputs.privateIp
        }
      },
      indexOf(map(vmItems, item => item.key), 'ad') >= 0 ? {
        ad: {
        ansible_host: adIp
        ansible_connection: 'psrp'
        ansible_psrp_protocol: 'http'
        ansible_user: config.admin_user
        ansible_password: secrets.adminPassword
        psrp_ssh_proxy: deployJumpbox ? azhopVm[indexOf(map(vmItems, item => item.key), 'jumpbox')].outputs.privateIp : ''
        ansible_psrp_proxy: deployJumpbox ? 'socks5h://localhost:5985' : ''
        }
      } : {} ,
      indexOf(map(vmItems, item => item.key), 'ad2') >= 0 ? {
        ad2: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'ad2')].outputs.privateIp
          ansible_connection: 'psrp'
          ansible_psrp_protocol: 'http'
          ansible_user: config.admin_user
          ansible_password: secrets.adminPassword
          psrp_ssh_proxy: deployJumpbox ? azhopVm[indexOf(map(vmItems, item => item.key), 'jumpbox')].outputs.privateIp : ''
          ansible_psrp_proxy: deployJumpbox ? 'socks5h://localhost:5985' : ''
        }
      } : {} ,
      deployJumpbox ? {
        jumpbox : {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'jumpbox')].outputs.privateIp
          ansible_ssh_port: config.vms.jumpbox.sshPort
          ansible_ssh_common_args: ''
        }
      } : {},
      config.deploy_lustre ? {
        lustre: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'lustre')].outputs.privateIp
        }
        robinhood: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'robinhood')].outputs.privateIp
        }
      } : {},
      config.enable_remote_winviz ? {
        guacamole: {
          ansible_host: azhopVm[indexOf(map(vmItems, item => item.key), 'guacamole')].outputs.privateIp
        }
      } : {}
    )
    vars: {
      ansible_ssh_user: config.admin_user
      ansible_ssh_common_args: deployJumpbox ? '-o ProxyCommand="ssh -i ${config.admin_user}_id_rsa -p ${config.vms.jumpbox.sshPort} -W %h:%p ${config.admin_user}@${azhopVm[indexOf(map(vmItems, item => item.key), 'jumpbox')].outputs.privateIp}"' : ''
    }
  }
}

// need to add this to the inventory file as bicep will not allow me to generate it
output lustre_oss_private_ips array = [for i in range(0, lustreOssCount): azhopVm[indexOf(map(vmItems, item => item.key), format('lustre-oss-{0}', i))].outputs.privateIp]

output azhopPackerOptions object = (config.deploy_sig) ? {
  var_subscription_id: subscription().subscriptionId
  var_resource_group: azhopResourceGroupName
  var_location: location
  var_sig_name: 'azhop_${resourcePostfix}'
  var_private_virtual_network_with_public_ip: 'false'
  var_virtual_network_name: config.vnet.name
  var_virtual_network_subnet_name: config.vnet.subnets.compute.name
  var_virtual_network_resource_group_name: azhopResourceGroupName
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
''', config.admin_user, config.vms.jumpbox.sshPort, azhopVm[indexOf(map(vmItems, item => item.key), 'jumpbox')].outputs.privateIp)

output azhopConnectScript string = deployDeployer ? azhopConnectScript : azhopSSHConnectScript


output azhopGetSecretScript string = format('''
#!/bin/bash

user=$1
# Because secret names are restricted to '^[0-9a-zA-Z-]+$' we need to remove all other characters
secret_name=$(echo $user-password | tr -dc 'a-zA-Z0-9-')

az keyvault secret show --vault-name kv{0} -n $secret_name --query "value" -o tsv

''', resourcePostfix)


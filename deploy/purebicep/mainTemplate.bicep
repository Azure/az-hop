targetScope = 'subscription'

//param azhopResourceGroupName string

@description('Azure region to use')
param location string = deployment().location

@description('Deploy a VPN Gateway or not. Default to false')
param deployGateway bool = false
@description('Deploy a an Azure Bastion or not. Default to false')
param deployBastion bool = false

@description('Deploy a SIG or not. Default to false')
param deploySIG bool = false

// @description('Enable the usage of Public IP. Default to true')
// param publicIp bool = true
// param keyvaultReaderOid string = ''

@description('Identity of the deployer if not deploying from a deployer VM')
param loggedUserObjectId string = ''

@description('Run software installation from the Deployer VM. Default to true')
param softwareInstallFromDeployer bool = true

// @description('Admin user name for VMs. Default to hpcadmin')
// param adminUser string = 'hpcadmin'

@description('Branch of the azhop repo to pull - Default to main')
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
// todo: change to database admin password
@secure()
param slurmAccountingAdminPassword string = ''

// @description('Queue manager to configure - Default to slurm')
// param queueManager string = 'slurm'

// @description('SSH Port to communicate with the deployer VM - Default to 22')
// param deployerSshPort string = '22'

// @description('VNet Peerings - Array')
// param vnetPeerings array = []

// @description('Enable Windows Remote Viz')
// param enableRemoteWinviz bool = false

param vnetTags object = {}
// param vnetCidr string = '10.0.0.0/23'
// param subnetFrontendCidr string = '10.0.0.0/29'
// param subnetAdCidr string = '10.0.0.8/29'
// param subnetAdminCidr string = '10.0.0.16/28'
// param subnetNetappCidr string = '10.0.0.32/28'
// param subnetOutboundDnsCidr string = '10.0.0.48/28'
// param subnetBastionCidr string = '10.0.0.64/26'
// param subnetGatewayCidr string = '10.0.0.128/27'
// param subnetComputeCidr string = '10.0.1.0/24'

@description('Input configuration file in json format')
param azhopConfig object

// Local variables to help in the simplication as functions doesn't exists
var jumpboxSshPort = contains(azhopConfig.jumpbox, 'ssh_port') ? azhopConfig.jumpbox.ssh_port : 22
var deployLustre = contains(azhopConfig, 'lustre') ? true : false
var enableWinViz = contains(azhopConfig, 'enable_remote_winviz') ? azhopConfig.enable_remote_winviz : false
var highAvailabilityForAD = contains(azhopConfig.ad, 'high_availability') ? azhopConfig.ad.high_availability : false

var linuxBaseImage = contains(azhopConfig, 'linux_base_image') ? azhopConfig.linux_base_image : 'OpenLogic:CentOS:7_9-gen2:latest'
var linuxBasePlan = contains(azhopConfig, 'linux_base_plan') ? azhopConfig.linux_base_plan : ''
var windowsBaseImage = contains(azhopConfig, 'windows_base_image') ? azhopConfig.windows_base_image : 'MicrosoftWindowsServer:WindowsServer:2019-Datacenter-smalldisk:latest'
var lustreBaseImage = contains(azhopConfig, 'lustre_base_image') ? azhopConfig.lustre_base_image : 'azhpc:azurehpc-lustre:azurehpc-lustre-2_12:latest'
var lustreBasePlan = contains(azhopConfig, 'lustre_base_plan') ? azhopConfig.lustre_base_plan : 'azhpc:azurehpc-lustre:azurehpc-lustre-2_12'

// Convert the azhop configuration file to a pivot format used for the deployment
var config = {
  admin_user: azhopConfig.admin_user
  keyvault_readers: contains(azhopConfig, 'key_vault_readers') ? ( empty(azhopConfig.key_vault_readers) ? [] : [ azhopConfig.key_vault_readers ] ) : []

  public_ip: contains(azhopConfig.locked_down_network, 'public_ip') ? azhopConfig.locked_down_network.public_ip : true
  deploy_gateway: deployGateway
  deploy_bastion: deployBastion
  deploy_lustre: deployLustre

  lock_down_network: {
    enforce: contains(azhopConfig.locked_down_network, 'enforce') ? azhopConfig.locked_down_network.enforce : false
    grant_access_from: contains(azhopConfig.locked_down_network, 'grant_access_from') ? ( empty(azhopConfig.locked_down_network.grant_access_from) ? [] : [ azhopConfig.locked_down_network.grant_access_from ] ) : []
  }

  queue_manager: contains(azhopConfig, 'queue_manager') ? azhopConfig.queue_manager : 'openpbs'

  slurm: {
    admin_user: contains(azhopConfig, 'database') ? (contains(azhopConfig.database, 'user') ? azhopConfig.database.user : 'sqladmin') : 'sqladmin'
    accounting_enabled: contains(azhopConfig.slurm, 'accounting_enabled') ? azhopConfig.slurm.accounting_enabled : false
    enroot_enabled: contains(azhopConfig.slurm, 'enroot_enabled') ? azhopConfig.slurm.enroot_enabled : false
  }

  enable_remote_winviz : enableWinViz
  deploy_sig: deploySIG

  homedir: 'nfsfiles'
  homedir_mountpoint: azhopConfig.mounts.home.mountpoint

  anf: {
    dual_protocol: contains(azhopConfig.anf, 'dual_protocol') ? azhopConfig.anf.dual_protocol : false
    service_level: contains(azhopConfig.anf, 'homefs_service_level') ? azhopConfig.anf.homefs_service_level : 'Standard'
    size_gb: contains(azhopConfig.anf, 'homefs_size_tb') ? azhopConfig.anf.homefs_size_tb*1024 : 4096
  }

  vnet: {
    tags: vnetTags
    name: azhopConfig.network.vnet.name
    cidr: azhopConfig.network.vnet.address_space
    subnets: union (
      {
      frontend: {
        name: azhopConfig.network.vnet.subnets.frontend.name
        cidr: azhopConfig.network.vnet.subnets.frontend.address_prefixes
        service_endpoints: [
          'Microsoft.Storage'
        ]
      }
      admin: {
        name: azhopConfig.network.vnet.subnets.admin.name
        cidr: azhopConfig.network.vnet.subnets.admin.address_prefixes
        service_endpoints: [
          'Microsoft.KeyVault'
          'Microsoft.Storage'
        ]
      }
      netapp: {
        apply_nsg: false
        name: azhopConfig.network.vnet.subnets.netapp.name
        cidr: azhopConfig.network.vnet.subnets.netapp.address_prefixes
        delegations: [
          'Microsoft.Netapp/volumes'
        ]
      }
      ad: {
        name: azhopConfig.network.vnet.subnets.ad.name
        cidr: azhopConfig.network.vnet.subnets.ad.address_prefixes
      }
      compute: {
        name: azhopConfig.network.vnet.subnets.compute.name
        cidr: azhopConfig.network.vnet.subnets.compute.address_prefixes
        service_endpoints: [
          'Microsoft.Storage'
        ]
      }
    },
    contains(azhopConfig.network.vnet.subnets,'bastion') ? {
      bastion: {
        apply_nsg: false
        name: 'AzureBastionSubnet'
        cidr: azhopConfig.network.vnet.subnets.bastion.address_prefixes
      }
    } : {},
    contains(azhopConfig.network.vnet.subnets,'outbounddns') ? {
      outbounddns: {
        name: azhopConfig.network.vnet.subnets.outbounddns.name
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
    peerings: azhopConfig.network.peering
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
      deployer: union(
        {
          subnet: 'frontend'
          sku: azhopConfig.jumpbox.vm_size
          osdisksku: 'Standard_LRS'
          image: 'ubuntu'
          pip: contains(azhopConfig.locked_down_network, 'public_ip') ? azhopConfig.locked_down_network.public_ip : true
          sshPort: jumpboxSshPort
          asgs: [ 'asg-ssh', 'asg-jumpbox', 'asg-deployer', 'asg-ad-client', 'asg-telegraf', 'asg-nfs-client' ]
        }, softwareInstallFromDeployer ? {
          deploy_script: replace(loadTextContent('install.sh'), '__INSERT_AZHOP_BRANCH__', branchName)
          identity: {
            keyvault: {
              key_permissions: [ 'All' ]
              secret_permissions: [ 'All' ]
            }
            roles: [
              'Contributor'
              'UserAccessAdministrator'
            ]
          }
        } : {
          deploy_script: jumpboxSshPort != 22 ? replace(loadTextContent('jumpbox.yml'), '__SSH_PORT__', string(jumpboxSshPort)) : ''
        }
      )
      ad: {
        subnet: 'ad'
        windows: true
        ahub: contains(azhopConfig.ad, 'hybrid_benefit') ? azhopConfig.ad.hybrid_benefit : false
        sku: azhopConfig.ad.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'win_base'
        asgs: [ 'asg-ad', 'asg-rdp', 'asg-ad-client' ]
      }
      ondemand: {
        subnet: 'frontend'
        sku: azhopConfig.ondemand.vm_size
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        pip: contains(azhopConfig.locked_down_network, 'public_ip') ? azhopConfig.locked_down_network.public_ip : true
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
          key_permissions: [ 'Get', 'List' ]
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
    deployLustre ? {
      lustre: {
        subnet: 'admin'
        sku: azhopConfig.lustre.mds_sku
        osdisksku: 'StandardSSD_LRS'
        image: 'lustre'
        asgs: [ 'asg-ssh', 'asg-lustre', 'asg-lustre-client', 'asg-telegraf' ]
      }
      'lustre-oss': {
        count: azhopConfig.lustre.oss_count
        identity: {
          keyvault: {
            key_permissions: [ 'Get', 'List' ]
            secret_permissions: [ 'Get', 'List' ]
          }
        }
        subnet: 'admin'
        sku: azhopConfig.lustre.oss_sku
        osdisksku: 'StandardSSD_LRS'
        image: 'lustre'
        asgs: [ 'asg-ssh', 'asg-lustre', 'asg-lustre-client', 'asg-telegraf' ]
      }
      robinhood: {
        identity: {
          keyvault: {
            key_permissions: [ 'Get', 'List' ]
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
    Public_Ssh: [string(jumpboxSshPort)]
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
      AllowHubSshIn               : ['200', 'Inbound', 'Allow', 'Tcp', 'Public_Ssh', 'tag', 'VirtualNetwork', 'asg', 'asg-jumpbox']
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

resource azhopResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: azhopConfig.resource_group
  location: location
}

module azhopDeployment './azhop.bicep' = {
  name: 'azhop'
  scope: azhopResourceGroup
  params: {
    location: location
    autogenerateSecrets: autogenerateSecrets
    adminSshPublicKey: adminSshPublicKey
    adminSshPrivateKey: adminSshPrivateKey
    adminPassword: adminPassword
    slurmAccountingAdminPassword: slurmAccountingAdminPassword
    softwareInstallFromDeployer: softwareInstallFromDeployer
    loggedUserObjectId: loggedUserObjectId
    config: config
  }
}

module azhopPeerings './vnetpeering.bicep' = [ for peer in config.vnet.peerings: {
  name: 'peer_from${peer.vnet_name}'
  scope: resourceGroup(peer.vnet_resource_group)
  params: {
    name: '${azhopConfig.resource_group}_${config.vnet.name}'
    vnetName: peer.vnet_name
    allowGateway: contains(peer, 'vnet_allow_gateway') ? peer.vnet_allow_gateway : true
    vnetId: azhopDeployment.outputs.vnetId
  }
}]

var subscriptionReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(azhopResourceGroup.id, subscriptionReaderRoleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionReaderRoleDefinitionId
    principalId: azhopDeployment.outputs.ccportalPrincipalId
    principalType: 'ServicePrincipal'
  }
}

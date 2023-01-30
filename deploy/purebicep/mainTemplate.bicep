targetScope = 'subscription'

param azhopResourceGroupName string

@description('Azure region to use')
param location string = deployment().location

@description('Deploy a VPN Gateway or not. Default to false')
param deployGateway bool = false
@description('Deploy a an Azure Bastion or not. Default to false')
param deployBastion bool = false
@description('Deploy a Lustre Cluster or not. Default to false')
param deployLustre bool = true
@description('Deploy a SIG or not. Default to false')
param deploySIG bool = false

@description('Enable the usage of Public IP. Default to true')
param publicIp bool = true
param keyvaultReaderOid string = ''

@description('Identity of the deployer if not deploying from a deployer VM')
param logged_user_objectId string = ''

@description('Run software installation from the Deployer VM. Default to true')
param softwareInstallFromDeployer bool = true

@description('Admin user name for VMs. Default to hpcadmin')
param adminUser string = 'hpcadmin'

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

@description('Queue manager to configure - Default to slurm')
param queue_manager string = 'slurm'

@description('SSH Port to communicate with the deployer VM - Default to 22')
param deployer_ssh_port string = '22'

@description('VNet Peerings - Array')
param vnetPeerings array = []

@description('Enable Windows Remote Viz')
param enable_remote_winviz bool = false


var config = {
  admin_user: adminUser
  keyvault_readers: (keyvaultReaderOid != '') ? [ keyvaultReaderOid ] : []

  public_ip: publicIp
  deploy_gateway: deployGateway
  deploy_bastion: deployBastion
  deploy_lustre: deployLustre

  lock_down_network: {
    enforce: false
    grant_access_from: []
  }

  queue_manager: queue_manager

  slurm: {
    admin_user: 'sqladmin'
    accounting_enabled: true
    enroot_enabled: true
  }

  enable_remote_winviz : enable_remote_winviz
  deploy_sig: deploySIG

  homedir: 'nfsfiles'
  homedir_mountpoint: '/anfhome'

  anf: {
    dual_protocol: false
    service_level: 'Standard'
    size_gb: 4096
  }

  vnet: {
    tags: {
      NRMSBastion: ''
    }
    name: 'hpcvnet'
    cidr: '10.201.0.0/16'
    subnets: {
      bastion: {
        apply_nsg: false
        name: 'AzureBastionSubnet'
        cidr: '10.201.0.0/24'
      }
      frontend: {
        name: 'frontend'
        cidr: '10.201.1.0/24'
        service_endpoints: [
          'Microsoft.Sql'
          'Microsoft.Storage'
        ]
      }
      admin: {
        name: 'admin'
        cidr: '10.201.2.0/24'
        service_endpoints: [
          'Microsoft.KeyVault'
          'Microsoft.Sql'
          'Microsoft.Storage'
        ]
      }
      netapp: {
        apply_nsg: false
        name: 'netapp'
        cidr: '10.201.3.0/24'
        delegations: [
          'Microsoft.Netapp/volumes'
        ]
      }
      ad: {
        name: 'ad'
        cidr: '10.201.4.0/24'
      }
      compute: {
        name: 'compute'
        cidr: '10.201.5.0/24'
        service_endpoints: [
          'Microsoft.Storage'
        ]
      }
      gateway: {
        apply_nsg: false
        name: 'GatewaySubnet'
        cidr: '10.201.6.0/24'
      }
      outbounddns: {
        name: 'outbounddns'
        cidr: '10.201.7.0/24'
        delegations: [
          'Microsoft.Network/dnsResolvers'
        ]
      }
    }
    peerings: vnetPeerings
  }

  images: {
    lustre: {
      plan: true
      ref: {
        publisher: 'azhpc'
        offer: 'azurehpc-lustre'
        sku: 'azurehpc-lustre-2_12'
        version: 'latest'
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
      ref: {
        publisher: 'OpenLogic'
        offer: 'CentOS'
        sku: '7_9-gen2'
        version: 'latest'
      }
    }
    win_base: {
      ref: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-smalldisk'
        version: 'latest'
      }
    }
  }
      
  vms: union(
    {
      deployer: union(
        {
          subnet: 'frontend'
          sku: 'Standard_B2ms'
          osdisksku: 'Standard_LRS'
          image: 'ubuntu'
          pip: false
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
          asgs: [ 'asg-ssh', 'asg-jumpbox', 'asg-deployer', 'asg-ad-client', 'asg-telegraf', 'asg-nfs-client' ]
        }, softwareInstallFromDeployer ? {
          deploy_script: replace(loadTextContent('install.sh'), '__INSERT_AZHOP_BRANCH__', branchName)
        } : {
          deploy_script: deployer_ssh_port != '22' ? replace(loadTextContent('jumpbox.yml'), '__SSH_PORT__', deployer_ssh_port) : ''
        }
      )
      ad: {
        subnet: 'ad'
        windows: true
        ahub: false
        sku: 'Standard_B2ms'
        osdisksku: 'StandardSSD_LRS'
        image: 'win_base'
        asgs: [ 'asg-ad', 'asg-rdp', 'asg-ad-client' ]
      }
      ondemand: {
        subnet: 'frontend'
        sku: 'Standard_D4s_v5'
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        pip: false
        asgs: union(
          [ 'asg-ssh', 'asg-ondemand', 'asg-ad-client', 'asg-nfs-client', 'asg-pbs-client', 'asg-telegraf', 'asg-guacamole', 'asg-cyclecloud-client', 'asg-mariadb-client' ],
          deployLustre ? [ 'asg-lustre-client' ] : []
        )
      }
      grafana: {
        subnet: 'admin'
        sku: 'Standard_B2ms'
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        asgs: [ 'asg-ssh', 'asg-grafana', 'asg-ad-client', 'asg-telegraf', 'asg-nfs-client' ]
      }
      ccportal: {
        subnet: 'admin'
        sku: 'Standard_B2ms'
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
        sku: 'Standard_B2ms'
        osdisksku: 'StandardSSD_LRS'
        image: 'linux_base'
        asgs: [ 'asg-ssh', 'asg-pbs', 'asg-ad-client', 'asg-cyclecloud-client', 'asg-nfs-client', 'asg-telegraf', 'asg-mariadb-client' ]
      }
    },
    enable_remote_winviz ? {
      guacamole: {
      identity: {
        keyvault: {
          key_permissions: [ 'Get', 'List' ]
          secret_permissions: [ 'Get', 'List' ]
        }
      }
      subnet: 'admin'
      sku: 'Standard_B2ms'
      osdisksku: 'StandardSSD_LRS'
      image: 'linux_base'
      asgs: [ 'asg-ssh', 'asg-ad-client', 'asg-telegraf', 'asg-nfs-client', 'asg-cyclecloud-client', 'asg-mariadb-client' ]
      }
    } : {},
    deployLustre ? {
      lustre: {
        subnet: 'admin'
        sku: 'Standard_D4d_v4'
        osdisksku: 'StandardSSD_LRS'
        image: 'lustre'
        asgs: [ 'asg-ssh', 'asg-lustre', 'asg-lustre-client', 'asg-telegraf' ]
      }
      'lustre-oss': {
        count: 2
        identity: {
          keyvault: {
            key_permissions: [ 'Get', 'List' ]
            secret_permissions: [ 'Get', 'List' ]
          }
        }
        subnet: 'admin'
        sku: 'Standard_D16d_v4'
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
        sku: 'Standard_D4d_v4'
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
    Public_Ssh: [deployer_ssh_port]
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
  name: azhopResourceGroupName
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
    deployer_ssh_port: deployer_ssh_port
    logged_user_objectId: logged_user_objectId
    config: config
  }
}

module azhopPeerings './vnetpeering.bicep' = [ for peer in config.vnet.peerings: {
  name: 'peer_from${peer.vnet_name}'
  scope: resourceGroup(peer.vnet_resource_group)
  params: {
    name: '${azhopResourceGroupName}_${config.vnet.name}'
    vnetName: peer.vnet_name
    allowGateway: contains(peer, 'vnet_allow_gateway') ? peer.vnet_allow_gateway : true
    vnetId: azhopDeployment.outputs.vnetId
  }
}]

var subscriptionReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(azhopResourceGroup.id, subscriptionReaderRoleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionReaderRoleDefinitionId
    principalId: azhopDeployment.outputs.ccportalPrincipalId
    principalType: 'ServicePrincipal'
  }
}

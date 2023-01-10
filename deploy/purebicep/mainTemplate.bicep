targetScope = 'subscription'

/*

Tasks

- anf (anf.bicep)
- asg (network.bicep)
- bastion (bastion.bicep)
- keyvault (keyvault.bicep)
- mariadb (mariadb.bicep)
- network (network.bicep)
- nfsfiles (nfsfiles.bicep)
- nsg (network.bicep)
- outputs
- parameters (mainTemplate.bicep)
- secrets (keyvault.bicep)
- sig (sig.bicep)
- storage (storage.bicep)
- telemetry (telemetry.bicep)
- vms (vm.bicep)
- vpngateway (vpngateway.bicep)

*/

param azhopResourceGroupName string

@description('Azure region to use')
param location string = deployment().location

param deployGateway bool = true
param deployBastion bool = true
param publicIp bool = false

param adminUser string

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
param slurmAccountingAdminPassword string = ''

var config = {
  admin_user: adminUser
  keyvault_readers: []

  public_ip: false
  deploy_gateway: true
  deploy_bastion: true

  lock_down_network: {
    enforce: false
    grant_access_from: []
  }

  queue_manager: 'slurm'

  vpn_gateway: true

  slurm: {
    admin_user: 'sqladmin'
    accounting_enabled: true
    enroot_enabled: true
  }

  deploy_sig: false

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
    }
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
        sku: '2016-Datacenter-smalldisk'
        version: 'latest'
      }
    }
  }
      
  vms: {
    deployer: {
      deploy_script: loadTextContent('install.sh')
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
    }
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
      asgs: [ 'asg-ssh', 'asg-ondemand', 'asg-ad-client', 'asg-nfs-client', 'asg-pbs-client', 'asg-lustre-client', 'asg-telegraf', 'asg-guacamole', 'asg-cyclecloud-client' ]
    }
    grafana: {
      subnet: 'admin'
      sku: 'Standard_B2ms'
      osdisksku: 'StandardSSD_LRS'
      image: 'linux_base'
      asgs: [ 'asg-ssh', 'asg-grafana', 'asg-ad-client', 'asg-telegraf', 'asg-nfs-client' ]
    }
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
      asgs: [ 'asg-ssh', 'asg-ad-client', 'asg-telegraf', 'asg-nfs-client', 'asg-cyclecloud-client' ]
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
      asgs: [ 'asg-ssh', 'asg-pbs', 'asg-ad-client', 'asg-cyclecloud-client', 'asg-nfs-client', 'asg-telegraf' ]
    }
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
  }

  asg_names: [ 
    'asg-ssh', 'asg-rdp', 'asg-jumpbox', 'asg-ad', 'asg-ad-client', 'asg-lustre', 'asg-lustre-client'
    'asg-pbs', 'asg-pbs-client', 'asg-cyclecloud', 'asg-cyclecloud-client', 'asg-nfs-client'
    'asg-telegraf', 'asg-grafana', 'asg-robinhood', 'asg-ondemand', 'asg-deployer', 'asg-guacamole'
  ]

  service_ports: {
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
  
    internet: {
      AllowInternetSshIn          : ['200', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'tag', 'Internet', 'asg', 'asg-jumpbox']
      AllowInternetHttpIn         : ['210', 'Inbound', 'Allow', 'Tcp', 'Web', 'tag', 'Internet', 'asg', 'asg-ondemand']
    }
    hub: {
      AllowHubSshIn               : ['200', 'Inbound', 'Allow', 'Tcp', 'Ssh', 'tag', 'VirtualNetwork', 'asg', 'asg-jumpbox']
      AllowHubHttpIn              : ['210', 'Inbound', 'Allow', 'Tcp', 'Web', 'tag', 'VirtualNetwork', 'asg', 'asg-ondemand']
    }
    bastion: {
      AllowBastionIn              : ['530', 'Inbound', 'Allow', 'Tcp', 'Bastion', 'subnet', 'bastion', 'tag', 'VirtualNetwork']
    }
    gateway: {
      AllowInternalWebUsersIn     : ['540', 'Inbound', 'Allow', 'Tcp', 'Web', 'subnet', 'gateway', 'asg', 'asg-ondemand']
    }
  }

}

var resourcePostfix = '${uniqueString(subscription().subscriptionId, azhopResourceGroupName)}x'

resource azhopResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: azhopResourceGroupName
  location: location
}

module azhopSecrets './secrets.bicep' = if (autogenerateSecrets) {
  name: 'azhopSecrets'
  scope: azhopResourceGroup
  params: {
    location: location
  }
}

var secrets = (autogenerateSecrets) ? azhopSecrets.outputs.secrets : {
  adminSshPublicKey: adminSshPublicKey
  adminSshPrivateKey: adminSshPrivateKey
  adminPassword: adminPassword
  slurmAccountingAdminPassword: slurmAccountingAdminPassword
}

module azhopNetwork './network.bicep' = {
  name: 'azhopNetwork'
  scope: azhopResourceGroup
  params: {
    location: location
    deployGateway: deployGateway
    deployBastion: deployBastion
    publicIp: publicIp
    vnet: config.vnet
    asgNames: config.asg_names
    servicePorts: config.service_ports
    nsgRules: config.nsg_rules
  }
}

var subnetIds = azhopNetwork.outputs.subnetIds

module azhopBastion './bastion.bicep' = if (deployBastion) {
  name: 'azhopBastion'
  scope: azhopResourceGroup
  params: {
    location: location
    subnetId: subnetIds.bastion
  }
}

var vmItems = items(config.vms)

module azhopVm './vm.bicep' = [ for vm in vmItems: {
  name: 'azhopVm${vm.key}'
  scope: azhopResourceGroup
  params: {
    location: location
    name: vm.key
    vm: vm.value
    image: config.images[vm.value.image]
    subnetId: subnetIds[vm.value.subnet]
    adminUser: adminUser
    secrets: secrets
  }
}]

var keyvaultSecrets = union(
  [
    {
      name: '${adminUser}-password'
      value: secrets.adminPassword
    }
    {
      name: '${adminUser}-pubkey'
      value: secrets.adminSshPublicKey
    }
    {
      name: '${adminUser}-privkey'
      value: secrets.adminSshPrivateKey
    }
  ],
  (config.queue_manager == 'slurm' && config.slurm.accounting_enabled) ? [
    {
      name: '${config.slurm.admin_user}-password'
      value: secrets.slurmAccountingAdminPassword
    }
  ] : []
)

module azhopKeyvault './keyvault.bicep' = {
  name: 'azhopKeyvault'
  scope: azhopResourceGroup
  params: {
    location: location
    resourcePostfix: resourcePostfix
    subnetId: subnetIds.admin
    keyvaultReaderOids: config.keyvault_readers
    lockDownNetwork: config.lock_down_network.enforce
    allowableIps: config.lock_down_network.grant_access_from
    identityPerms: [ for i in range(0, length(vmItems)): {
      principalId: azhopVm[i].outputs.principalId
      key_permissions: (contains(vmItems[i].value, 'identity') && contains(vmItems[i].value.identity, 'keyvault')) ? vmItems[i].value.identity.keyvault.key_permissions : []
      secret_permissions: (contains(vmItems[i].value, 'identity') && contains(vmItems[i].value.identity, 'keyvault')) ? vmItems[i].value.identity.keyvault.secret_permissions : []
    }]
    secrets: keyvaultSecrets
  }
}

module azhopStorage './storage.bicep' = {
  name: 'azhopStorage'
  scope: azhopResourceGroup
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
  scope: azhopResourceGroup
  params: {
    location: location
    resourcePostfix: resourcePostfix
  }
}

module azhopMariaDB './mariadb.bicep' = if (config.queue_manager == 'slurm' && config.slurm.accounting_enabled) {
  name: 'azhopMariaDB'
  scope: azhopResourceGroup
  params: {
    location: location
    resourcePostfix: resourcePostfix
    adminUser: config.slurm.admin_user
    adminPassword: secrets.slurmAccountingAdminPassword
    adminSubnetId: subnetIds.admin
    frontendSubnetId: subnetIds.frontend
  }
}

module azhopTelemetry './telemetry.bicep' = {
  name: 'azhopTelemetry'
  scope: azhopResourceGroup
}

module azhopVpnGateway './vpngateway.bicep' = if (config.deploy_gateway) {
  name: 'azhopVpnGateway'
  scope: azhopResourceGroup
  params: {
    location: location
    subnetId: subnetIds.gateway
  }
}

module azhopAnf './anf.bicep' = if (config.homedir == 'anf') {
  name: 'azhopAnf'
  scope: azhopResourceGroup
  params: {
    location: location
    resourcePostfix: resourcePostfix
    dualProtocol: config.anf.dual_protocol
    subnetId: subnetIds.netapp
    adUser: config.admin_user
    adPassword: secrets.adminPassword
    adDns: azhopVm[indexOf(map(vmItems, item => item.key), 'ad')].outputs.privateIps[0]
    serviceLevel: config.anf.service_level
    sizeGB: config.anf.size_gb
  }
}

module azhopNfsFiles './nfsfiles.bicep' = if (config.homedir == 'nfsfiles') {
  name: 'azhopNfsFiles'
  scope: azhopResourceGroup
  params: {
    location: location
    resourcePostfix: resourcePostfix
    allowedSubnetIds: [ subnetIds.admin, subnetIds.compute, subnetIds.frontend ]
    sizeGB: 1024
  }
}

output azhopConfig object = {
  location: location
  resource_group: azhopResourceGroupName
  //use_existing_rg: false
  //tags: {
  //  env: 'dev'
  //  project: 'azhop'
  //}
  //anf: {
  //  homefs_size_tb: 4
  //  homefs_service_level: 'Standard'
  //  dual_protocol: false
  //}

  // These mounts will be listed in the Files menu of the OnDemand portal and automatically mounted on all compute nodes and remote desktop nodes
  mounts: {
    // mount settings for the user home directory
    home: { // This home name can't be changed
      mountpoint: '/anfhome' // /sharedhome for example
      server: '{{anf_home_ip}}' // Specify an existing NFS server name or IP, when using the ANF built in use '{{anf_home_ip}}'
      export: '{{anf_home_path}}' // Specify an existing NFS export directory, when using the ANF built in use '{{anf_home_path}}'
      options: 'rw,hard,rsize=262144,wsize=262144,vers=3,tcp' // Specify the mount options. Default to rw,hard,rsize=262144,wsize=262144,vers=3,tcp
    }
  //  mount1:
  //    mountpoint: /mount1 
  //    server: a.b.c.d // Specify an existing NFS server name or IP
  //    export: myexport1 // Specify an existing NFS export name
  //    options: my_options // Specify the mount options.
  }

  admin_user: 'hpcadmin'
  //key_vault_readers: '' //<object_id>
  
  /*
  network: {
    // Create Network and Application Security Rules, true by default, false when using an existing VNET if not specified
    create_nsg: true
    vnet: {
      name: 'hpcvnet' // Optional - default to hpcvnet
      id: '' // If a vnet id is set then no network will be created and the provided vnet will be used
      address_space: '10.0.0.0/16' // Optional - default to "10.0.0.0/16"
      // When using an existing VNET, only the subnet names will be used and not the adress_prefixes
      subnets: { // all subnets are optionals
      // name values can be used to rename the default to specific names, address_prefixes to change the IP ranges to be used
      // All values below are the default values
        frontend: {
          name: 'frontend'
          address_prefixes: '10.0.0.0/24'
          create: true // create the subnet if true. default to true when not specified, default to false if using an existing VNET when not specified
        }
        admin: {
          name: 'admin'
          address_prefixes: '10.0.1.0/24'
          create: true
        }
        netapp: {
          name: 'netapp'
          address_prefixes: '10.0.2.0/24'
          create: true
        }
        ad: {
          name: 'ad'
          address_prefixes: '10.0.3.0/28'
          create: true
        }
        // Bastion and Gateway subnets are optional and can be added if a Bastion or a VPN need to be created in the environment
        // bastion: // Bastion subnet name is always fixed to AzureBastionSubnet
        //   address_prefixes: "10.0.4.0/27" // CIDR minimal range must be /27
        //   create: true
        // gateway: // Gateway subnet name is always fixed to GatewaySubnet
        //   address_prefixes: "10.0.4.32/27" // Recommendation is to use /27 or /28 network
        //   create: true
        compute: {
          name: 'compute'
          address_prefixes: '10.0.16.0/20'
          create: true
        }
      }
    }
  }
*/
  //  peering: // This list is optional, and can be used to create VNet Peerings in the same subscription.
  //    - vnet_name: //"VNET Name to Peer to"
  //      vnet_resource_group: //"Resource Group of the VNET to peer to"
  //      vnet_allow_gateway: false // optional: allow gateway transit (default: true)

  // Specify DNS forwarders available in the network
  // dns:
  //   forwarders:
  //     - { name: foo.com, ips: "10.2.0.4, 10.2.0.5" }
  
  // When working in a locked down network, uncomment and fill out this section
  locked_down_network: {
    enforce: false
  //   grant_access_from: [a.b.c.d] // Array of CIDR to grant access from, see https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal//grant-access-from-an-internet-ip-range
    public_ip: config.public_ip // Enable public IP creation for Jumpbox, OnDemand and create images. Default to true
  }

  /*
  // Base image configuration. Can be either an image reference or an image_id from the image registry or a custom managed image
  linux_base_image: 'OpenLogic:CentOS:7_9-gen2:latest' // publisher:offer:sku:version or image_id
  linux_base_plan: '' // linux image plan if required, format is publisher:product:name
  windows_base_image: 'MicrosoftWindowsServer:WindowsServer:2019-Datacenter-smalldisk:latest' // publisher:offer:sku:version or image_id
  lustre_base_image: 'azhpc:azurehpc-lustre:azurehpc-lustre-2_12:latest'
  // The lustre plan to use. Only needed when using the default lustre image from the marketplace. use "::" for an empty plan
  lustre_base_plan: 'azhpc:azurehpc-lustre:azurehpc-lustre-2_12' // publisher:product:name

  // Jumpbox VM configuration, only needed when deploying thru a public IP and without a configured deployer VM
  jumpbox: {
    vm_size: 'Standard_B2ms'
    // SSH port under which the jumpbox SSH server listens on the public IP. Default to 22
    // Change this to, e.g., 2222, if security policies (like "zero trust") in your tenant automatically block access to port 22 from the internet
    //ssh_port: 2222
  }
  // Active directory VM configuration
  ad: {
    vm_size: 'Standard_B2ms'
    hybrid_benefit: false // Enable hybrid benefit for AD, default to false
    high_availability: false // Build AD in High Availability mode (2 Domain Controlers) - default to false
  }
  // On demand VM configuration
  ondemand: {
    vm_size: 'Standard_D4s_v5'
    //fqdn: azhop.foo.com // When provided it will be used for the certificate server name
    generate_certificate: true // Generate an SSL certificate for the OnDemand portal. Default to true
  }
  // Grafana VM configuration
  grafana: {
    vm_size: 'Standard_B2ms'
  }
  // Guacamole VM configuration
  guacamole: {
    vm_size: 'Standard_B2ms'
  }
  // Scheduler VM configuration
  scheduler: {
    vm_size: 'Standard_B2ms'
  }
  // CycleCloud VM configuration
  cyclecloud: {
    vm_size: 'Standard_B2ms'
    // version: 8.3.0-3062 // to specify a specific version, see https://packages.microsoft.com/yumrepos/cyclecloud/
  }
  */

  // Lustre cluster is optional and can be used to create a Lustre cluster in the environment.
  // Uncomment the whole section if you want to create a Lustre cluster.
  // lustre:
  //   rbh_sku: "Standard_D8d_v4"
  //   mds_sku: "Standard_D8d_v4"
  //   oss_sku: "Standard_D32d_v4"
  //   oss_count: 2
  //   hsm_max_requests: 8
  //   mdt_device: "/dev/sdb"
  //   ost_device: "/dev/sdb"
  //   hsm:
  //     // optional to use existing storage for the archive
  //     // if not included it will use the azhop storage account that is created
  //     storage_account: //existing_storage_account_name
  //     storage_container: //only_used_with_existing_storage_account
  // List of users to be created on this environment
  users: [
    // name: username - must be less than 20 characters
    // uid: uniqueid
    // shell: /bin/bash // default to /bin/bash
    // home: /anfhome/<user_name> // default to /homedir_mountpoint/user_name
    // groups: list of groups the user belongs to
    { name: 'clusteradmin', uid: 10001, groups: [5001, 5002] }
    { name: 'hpcuser', uid: 10002 }
    // - { name: user1, uid: 10003, groups: [6000] }
    // - { name: user2, uid: 10004, groups: [6001] }
  ]
  usergroups: [
  // These groups can’t be changed
    {
      name: 'Domain Users' // All users will be added to this one by default
      gid: 5000
    }
    {
      name: 'az-hop-admins'
      gid: 5001
      description: 'For users with azhop admin privileges'
    }
    {
      name: 'az-hop-localadmins'
      gid: 5002
      description: 'For users with sudo right or local admin right on nodes'
    }
  // For custom groups use gid >= 6000
    // - name: project1 // For project1 users
    //   gid: 6000
    // - name: project2 // For project2 users
    //   gid: 6001
  ]

  // Enable cvmfs-eessi - disabled by default
  cvmfs_eessi: {
    enabled: false
  }

  // scheduler to be installed and configured (openpbs, slurm)
  queue_manager: config.queue_manager

  // Specific SLURM configuration
  slurm: {
    // Enable SLURM accounting, this will create a SLURM accounting database in a managed MySQL server instance
    accounting_enabled: config.slurm.accounting_enabled
    // Enable container support for SLURM using Enroot/Pyxis
    enroot_enabled: config.slurm.enroot_enabled
  }

  // Authentication configuration for accessing the az-hop portal
  // Default is basic authentication. For oidc authentication you have to specify the following values
  // The OIDCClient secret need to be stored as a secret named <oidc-client-id>-password in the keyvault used by az-hop
  authentication: {
    httpd_auth: 'basic' // oidc or basic
    // User mapping https://osc.github.io/ood-documentation/latest/reference/files/ood-portal-yml.html//ood-portal-generator-user-map-match
    // You can specify either a map_match or a user_map_cmd
    // Domain users are mapped to az-hop users with the same name and without the domain name
    // user_map_match: '^([^@]+)@mydomain.foo$'
    // If using a custom mapping script, update it from the ./playbooks/files directory before running the playbook
    // user_map_cmd: /opt/ood/ood_auth_map/bin/custom_mapping.sh
    // ood_auth_openidc:
    //   OIDCProviderMetadataURL: // for AAD use 'https://sts.windows.net/{{tenant_id}}/.well-known/openid-configuration'
    //   OIDCClientID: 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
    //   OIDCRemoteUserClaim: // for AAD use 'upn'
    //   OIDCScope: // for AAD use 'openid profile email groups'
    //   OIDCPassIDTokenAs: // for AAD use 'serialized'
    //   OIDCPassRefreshToken: // for AAD use 'On'
    //   OIDCPassClaimsAs: // for AAD use 'environment'
  }

  // List of images to be defined
  images: [
    // - name: image_definition_name // Should match the packer configuration file name, one per packer file
    //   publisher: azhop
    //   offer: CentOS
    //   sku: 7_9-gen2
    //   hyper_v: V2 // V1 or V2 (V1 is the default)
    //   os_type: Linux // Linux or Windows
    //   version: 7.9 // Version of the image to create the image definition in SIG. Pattern is major.minor where minor is mandatory
  // Pre-defined images
    {
      name: 'azhop-almalinux85-v2-rdma-gpgpu'
      publisher: 'azhop'
      offer: 'almalinux'
      sku: '8_5-hpc-gen2'
      hyper_v: 'V2'
      os_type: 'Linux'
      version: '8.5'
    }
    {
      name: 'azhop-centos79-v2-rdma-gpgpu'
      publisher: 'azhop'
      offer: 'CentOS'
      sku: '7.9-gen2'
      hyper_v: 'V2'
      os_type: 'Linux'
      version: '7.9'
    }
    // Image definition when using a custom image to build compute nodes images
    {
      name: 'azhop-centos79-v2-rdma-ci'
      publisher: 'azhop'
      offer: 'CentOS'
      sku: '7.9-gen2-ci'
      hyper_v: 'V2'
      os_type: 'Linux'
      version: '7.9'
    }
    // Image definition when using a custom image to build remote viz nodes images
    {
      name: 'azhop-centos79-desktop3d-ci'
      publisher: 'azhop'
      offer: 'CentOS'
      sku: '7.9-gen2-desktop3d-ci'
      hyper_v: 'V2'
      os_type: 'Linux'
      version: '7.9'
    }
    {
      name: 'azhop-centos79-desktop3d'
      publisher: 'azhop'
      offer: 'CentOS'
      sku: '7.9-gen2-desktop3d'
      hyper_v: 'V2'
      os_type: 'Linux'
      version: '7.9'
    }
    {
      name: 'azhop-compute-centos-7_9'
      publisher: 'azhpc'
      offer: 'azhop-compute'
      sku: 'centos-7_9'
      hyper_v: 'V2'
      os_type: 'Linux'
      version: '7.9'
    }
    {
      name: 'azhop-desktop-centos-7_9'
      publisher: 'azhpc'
      offer: 'azhop-desktop'
      sku: 'centos-7_9'
      hyper_v: 'V2'
      os_type: 'Linux'
      version: '7.9'
    }
    {
      name: 'azhop-compute-ubuntu-1804'
      publisher: 'azhpc'
      offer: 'azhop-compute'
      sku: 'ubuntu-1804'
      hyper_v: 'V2'
      os_type: 'Linux'
      version: '18.04'
    }
    {
      name: 'azhop-win10'
      publisher: 'azhop'
      offer: 'Windows-10'
      sku: '21h1-pron'
      hyper_v: 'V1'
      os_type: 'Windows'
      version: '10.19043'
    }
    // Base image when building your own HPC image and not using the HPC marketplace images
    {
      name: 'base-centos79-v2-rdma'
      publisher: 'azhop'
      offer: 'CentOS'
      sku: '7.9-gen2-rdma-nogpu'
      hyper_v: 'V2'
      os_type: 'Linux'
      version: '7.9'
    }
  ]

  // Autoscale default settings for all queues, can be overriden on each queue depending on the VM type if needed
  autoscale: {
    idle_timeout: 1800 // Idle time in seconds before shutting down VMs - default to 1800 like in CycleCloud
  }

  // List of queues (node arrays in Cycle) to be defined
  // don't use queue names longer than 8 characters in order to leave space for node suffix, as hostnames are limited to 15 chars due to domain join and NETBIOS constraints.
  queues: [
    {
      name: 'execute' // name of the Cycle Cloud node array
      // Azure VM Instance type
      vm_size: 'Standard_F2s_v2'
      // maximum number of cores that can be instanciated
      max_core_count: 1024
      // Use the pre-built azhop image from the marketplace
      image: 'azhpc:azhop-compute:centos-7_9:latest'
      // Use this image ID when building your own custom images
      //image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-v2-rdma-gpgpu/latest
      // Image plan specification (when needed for the image). Terms must be accepted prior to deployment
      // plan: publisher:product:name
      // Set to true if AccelNet need to be enabled. false is the default value
      EnableAcceleratedNetworking: 'false'
      // spot instance support. Default is false
      spot: 'false'
      // Set to false to disable creation of placement groups (for SLURM only). Default is true
      ColocateNodes: 'false'
      // Specific idle time in seconds before shutting down VMs, make sure it's lower than autoscale.idle_timeout
      idle_timeout: 300
      // Set the max number of vm's in a VMSS; requires additional limit raise through support ticket for >100; 
      // 100 is default value; lower numbers will improve scaling for single node jobs or jobs with small number of nodes
      MaxScaleSetSize: 100
    }
    {
      name: 'hc44rs'
      vm_size: 'Standard_HC44rs'
      max_core_count: 440
      image: 'azhpc:azhop-compute:centos-7_9:latest'
      spot: true
      EnableAcceleratedNetworking: true
    }
    {
      name: 'hb120v2'
      vm_size: 'Standard_HB120rs_v2'
      max_core_count: 1200
      image: 'azhpc:azhop-compute:centos-7_9:latest'
      spot: true
      EnableAcceleratedNetworking: true
    }
    {
      name: 'hb120v3'
      vm_size: 'Standard_HB120rs_v3'
      max_core_count: 1200
      image: 'azhpc:azhop-compute:centos-7_9:latest'
      spot: true
      EnableAcceleratedNetworking: true
    }
      // Queue dedicated to GPU remote viz nodes. This name is fixed and can't be changed
    {
      name: 'viz3d'
      vm_size: 'Standard_NV12s_v3'
      max_core_count: 48
      // Use the pre-built azhop image from the marketplace
      image: 'azhpc:azhop-desktop:centos-7_9:latest'
      // Use this image ID when building your own custom images
      //image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-desktop3d/latest
      ColocateNodes: false
      spot: false
      EnableAcceleratedNetworking: true
      max_hours: 12 // Maximum session duration
      min_hours: 1 // Minimum session duration - 0 is infinite
    }
      // Queue dedicated to share GPU remote viz nodes. This name is fixed and can't be changed
    {
      name: 'largeviz3d'
      vm_size: 'Standard_NV48s_v3'
      max_core_count: 96
      image: 'azhpc:azhop-desktop:centos-7_9:latest'
      ColocateNodes: false
      EnableAcceleratedNetworking: true
      spot: false
      max_hours: 12
      min_hours: 1
    }
      // Queue dedicated to non GPU remote viz nodes. This name is fixed and can't be changed
    {
      name: 'viz'
      vm_size: 'Standard_D8s_v5'
      max_core_count: 200
      image: 'azhpc:azhop-desktop:centos-7_9:latest'
      ColocateNodes: false
      spot: false
      EnableAcceleratedNetworking: true
      max_hours: 12
      min_hours: 1
    }
  ]

  // Remote Visualization definitions
  enable_remote_winviz: false // Set to true to enable windows remote visualization

  remoteviz: [
    {
      name: 'winviz' // This name is fixed and can't be changed
      vm_size: 'Standard_NV12s_v3' // Standard_NV8as_v4 Only NVsv3 and NVsV4 are supported
      max_core_count: 48
      image: 'MicrosoftWindowsDesktop:Windows-10:21h1-pron:latest'
      ColocateNodes: false
      spot: false
      EnableAcceleratedNetworking: true
    }
  ]

  // Application settings
  applications: {
    bc_codeserver: {
      enabled: true
    }
    bc_jupyter: {
      enabled: true
    }
    bc_ansys_workbench: {
      enabled: false
    }
  }
}

var envNameToCloudMap = {
  AzureCloud: 'AZUREPUBLICCLOUD'
  AzureUSGovernment: 'AZUREUSGOVERNMENT'
  AzureGermanCloud: 'AZUREGERMANCLOUD'
  AzureChinaCloud: 'AZURECHINACLOUD'
}

var kvSuffix = environment().suffixes.keyvaultDns

output azhopGlobalConfig object = union(
  {
    global_ssh_public_key         : secrets.ssh_public_key
    global_cc_storage             : 'azhop${resourcePostfix}'
    compute_subnetid              : '${azhopResourceGroupName}/${config.vnet.name}/${config.vnet.subnets.compute.name}'
    global_config_file            : '/az-hop/config.yml'
    primary_dns                   : azhopVm[indexOf(map(vmItems, item => item.key), 'ad')].outputs.privateIps[0]
    secondary_dns                 : azhopVm[indexOf(map(vmItems, item => item.key), 'ad')].outputs.privateIps[0]
    ad_join_user                  : adminUser
    ad_join_domain                : 'hpc.azure'
    ldap_server                   : 'ad'
    homedir_mountpoint            : config.homedir_mountpoint
    ondemand_fqdn                 : config.public_ip ? azhopVm[indexOf(map(vmItems, item => item.key), 'ondemand')].outputs.fqdn : azhopVm[indexOf(map(vmItems, item => item.key), 'ondemand')].outputs.privateIps[0]
    ansible_ssh_private_key_file  : '${adminUser}_id_rsa'
    subscription_id               : subscription().subscriptionId
    tenant_id                     : subscription().tenantId
    key_vault                     : 'kv${resourcePostfix}'
    sig_name                      : 'azhop_${resourcePostfix}'
    lustre_hsm_storage_account    : 'azhop${resourcePostfix}'
    lustre_hsm_storage_container  : 'lustre'
    slurmdb_fqdn                  : azhopMariaDB.outputs.mysql_fqdn
    slurmdb_user                  : config.slurm.admin_user
    azure_environment             : envNameToCloudMap[environment().name]
    key_vault_suffix              : substring(kvSuffix, 1, length(kvSuffix) - 1) //'vault.azure.net' - remove leading dot from env
    blob_storage_suffix           : environment().suffixes.storage //'blob.core.windows.net'
    jumpbox_ssh_port              : 22
  },
  config.homedir == 'anf' ? {
    anf_home_ip                   : azhopAnf.outputs.nfs_home_ip
    anf_home_path                 : azhopAnf.outputs.nfs_home_path
    anf_home_opts                 : azhopAnf.outputs.nfs_home_opts
  } : {},
  config.homedir == 'nfsfiles' ? {
    anf_home_ip                   : azhopNfsFiles.outputs.nfs_home_ip
    anf_home_path                 : azhopNfsFiles.outputs.nfs_home_path
    anf_home_opts                 : azhopNfsFiles.outputs.nfs_home_opts
  } : {}
)


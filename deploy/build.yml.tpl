---
#admin_user: hpcadmin # parameter
keyvault_readers: [] # list of object IDs to grant read access

lock_down_network:
  enforce: false
  grant_access_from: [] # list in CIDR notation

queue_manager: openpbs

slurm:
  #admin_user: sqladmin # parameter
  accounting_enabled: true

deploy_sig: true

homedir: "anf"

anf:
  dual_protocol: false
  service_level: Standard
  size_tb: 4

vnet:
  tags:
    NRMSBastion: ''
  name: hpcvnet
  cidr: '10.201.0.0/16'
  subnets:
    bastion:
      apply_nsg: false
      name: AzureBastionSubnet
      cidr: '10.201.0.0/24'
    frontend:
      name: frontend
      cidr: '10.201.1.0/24'
      service_endpoints: 
        - Microsoft.Sql
    admin:
      name: admin
      cidr: '10.201.2.0/24'
      service_endpoints: 
        - Microsoft.KeyVault
        - Microsoft.Sql
        - Microsoft.Storage
    netapp:
      apply_nsg: false
      name: netapp
      cidr: '10.201.3.0/24'
      delegation: Microsoft.NetApp/volumes
    ad:
      name: ad
      cidr: '10.201.4.0/24'
    compute:
      name: compute
      cidr: '10.201.5.0/24'
      service_endpoints:
        - Microsoft.Storage

images:
  lustre:
    plan: true
    publisher: azhpc
    offer: azurehpc-lustre
    sku: azurehpc-lustre-2_12
    version: latest
  ubuntu:
    publisher: Canonical
    offer: 0001-com-ubuntu-server-focal
    sku: 20_04-lts-gen2
    version: latest
  linux_base:
    publisher: OpenLogic
    offer: CentOS
    sku: 7_9-gen2
    version: latest
  win_base:
    publisher: MicrosoftWindowsServer
    offer: WindowsServer
    sku: 2016-Datacenter-smalldisk
    version: latest
  azhop-centos79-v2-rdma-gpgpu:
    id: <existing-marketplace-image-or-marketplace-id>
  centos-7.8-desktop-3d:
    id: <existing-marketplace-image-or-marketplace-id>
    
vms:
  deployer:
    run_deploy_script: true
    subnet: frontend
    sku: Standard_B2ms
    osdisksku: Standard_LRS
    image: ubuntu
    pip: true
    identity:
      keyvault:
        key_permissions: [ All ]
        secret_permissions: [ All ]
      roles:
        - Contributor
        - UserAccessAdministrator
    asgs: [ asg-ssh, asg-jumpbox, asg-ad-client, asg-telegraf, asg-nfs-client ]
  jumpbox:
    subnet: frontend
    sku: Standard_B2ms
    osdisksku: Standard_LRS
    image: linux_base
    pip: true
    asgs: [ asg-ssh, asg-jumpbox, asg-ad-client, asg-telegraf, asg-nfs-client ]
  ad:
    subnet: ad
    windows: true
    ahub: false
    sku: Standard_B2ms
    osdisksku: StandardSSD_LRS
    image: win_base
    asgs: [ asg-ad, asg-rdp ]
  ondemand:
    subnet: frontend
    sku: Standard_D4s_v5
    osdisksku: Standard_LRS
    image: linux_base
    pip: true
    asgs: [ asg-ssh, asg-ondemand, asg-ad-client, asg-nfs-client, asg-pbs-client, asg-lustre-client, asg-telegraf, asg-guacamole, asg-cyclecloud-client ]
  grafana:
    subnet: admin
    sku: Standard_B2ms
    osdisksku: Standard_LRS
    image: linux_base
    asgs: [ asg-ssh, asg-grafana, asg-ad-client, asg-telegraf, asg-nfs-client ]
  guacamole:
    identity:
      keyvault:
        key_permissions: [ Get, List ]
        secret_permissions: [ Get, List ]
    subnet: admin
    sku: Standard_B2ms
    osdisksku: Standard_LRS
    image: linux_base
    asgs: [ asg-ssh, asg-ad-client, asg-telegraf, asg-nfs-client, asg-cyclecloud-client ]
  ccportal:
    subnet: admin
    sku: Standard_B2ms
    osdisksku: Standard_LRS
    image: linux_base
    datadisks:
      - name: ccportal-datadisk0
        disksku: Premium_LRS
        size: 128
        caching: ReadWrite
    identity:
      roles:
        - Contributor
    asgs: [ asg-ssh, asg-cyclecloud, asg-telegraf, asg-ad-client ]
  scheduler:
    subnet: admin
    sku: Standard_B2ms
    osdisksku: Standard_LRS
    image: linux_base
    asgs: [ asg-ssh, asg-pbs, asg-ad-client, asg-cyclecloud-client, asg-nfs-client, asg-telegraf ]
  lustre:
    subnet: admin
    sku: Standard_D8d_v4
    osdisksku: StandardSSD_LRS
    image: lustre
    asgs: [ asg-ssh, asg-lustre, asg-lustre-client, asg-telegraf ]
  lustre-oss:
    count: 2
    identity:
      keyvault:
        key_permissions: [ Get, List ]
        secret_permissions: [ Get, List ]
    subnet: admin
    sku: Standard_D32d_v4
    osdisksku: StandardSSD_LRS
    image: lustre
    asgs: [ asg-ssh, asg-lustre, asg-lustre-client, asg-telegraf ]
  robinhood:
    identity:
      keyvault:
        key_permissions: [ Get, List ]
        secret_permissions: [ Get, List ]
    subnet: admin
    sku: Standard_D8d_v4
    osdisksku: StandardSSD_LRS
    image: lustre
    asgs: [ asg-ssh, asg-robinhood, asg-lustre-client, asg-telegraf ]


asgs: [ asg-ssh, asg-rdp, asg-jumpbox, asg-ad, asg-ad-client, asg-lustre, asg-lustre-client,
  asg-pbs, asg-pbs-client, asg-cyclecloud, asg-cyclecloud-client, asg-nfs-client,
  asg-telegraf, asg-grafana, asg-robinhood, asg-ondemand, asg-deployer, asg-guacamole
]

nsg_destination_ports:
  All: ['0-65535']
  Bastion: ['22', '3389']
  Web: ['443', '80']
  Ssh: ['22']
  Socks: ['5985']
  # DNS, Kerberos, RpcMapper, Ldap, Smb, KerberosPass, LdapSsl, LdapGc, LdapGcSsl, AD Web Services, RpcSam
  DomainControlerTcp: ['53', '88', '135', '389', '445', '464', '686', '3268', '3269', '9389', '49152-65535']
  # DNS, Kerberos, W32Time, NetBIOS, Ldap, KerberosPass, LdapSsl
  DomainControlerUdp: ['53', '88', '123', '138', '389', '464', '686']
  # Web, NoVNC, WebSockify
  NoVnc: ['80', '443', '5900-5910', '61001-61010']
  Dns: ['53']
  Rdp: ['3389']
  Pbs: ['6200', '15001-15009', '17001', '32768-61000', '6817-6819']
  Slurmd: ['6818']
  Lustre: ['635', '988']
  Nfs: ['111', '635', '2049', '4045', '4046']
  Telegraf: ['8086']
  Grafana: ['3000']
  # HTTPS, AMQP
  CycleCloud: ['9443', '5672']
  # MySQL
  MySQL: ['3306', '33060']


# Array of NSG rules to be applied on the common NSG
# NsgRuleName : [priority, direction, access, protocol, destination_port_range, source, destination]
#   - priority               : integer value from 100 to 4096
#   - direction              : Inbound, Outbound
#   - access                 : Allow, Deny
#   - protocol               : Tcp, Udp, *
#   - destination_port_range : name of one of the nsg_destination_ports defined above
#   - source                 : asg/<asg-name>, subnet/<subnet-name>, tag/<tag-name>. tag-name : any Azure tags like Internet, VirtualNetwork, AzureLoadBalancer, ...
#   - destination            : same as source
_nsg_rules:
    #  _   _   ____     ____       ___   _   _   ____     ___    _   _   _   _   ____  
    # | \ | | / ___|   / ___|  _  |_ _| | \ | | | __ )   / _ \  | | | | | \ | | |  _ \
    # |  \| | \___ \  | |  _  (_)  | |  |  \| | |  _ \  | | | | | | | | |  \| | | | | |
    # | |\  |  ___) | | |_| |  _   | |  | |\  | | |_) | | |_| | | |_| | | |\  | | |_| |
    # |_| \_| |____/   \____| (_) |___| |_| \_| |____/   \___/   \___/  |_| \_| |____/
    # AD communication
    AllowAdServerTcpIn          : ['220', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg/asg-ad',        'asg/asg-ad-client']
    AllowAdServerUdpIn          : ['230', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg/asg-ad',        'asg/asg-ad-client']
    AllowAdClientTcpIn          : ['240', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg/asg-ad-client', 'asg/asg-ad']
    AllowAdClientUdpIn          : ['250', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg/asg-ad-client', 'asg/asg-ad']
    AllowAdServerComputeTcpIn   : ['260', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg/asg-ad',        'subnet/compute']
    AllowAdServerComputeUdpIn   : ['270', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg/asg-ad',        'subnet/compute']
    AllowAdClientComputeTcpIn   : ['280', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet/compute',    'asg/asg-ad']
    AllowAdClientComputeUdpIn   : ['290', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet/compute',    'asg/asg-ad']
    AllowAdServerNetappTcpIn    : ['300', 'Inbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet/netapp',      'asg/asg-ad']
    AllowAdServerNetappUdpIn    : ['310', 'Inbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet/netapp',      'asg/asg-ad']

    # SSH internal rules
    AllowSshFromJumpboxIn       : ['320', 'Inbound', 'Allow', 'Tcp', 'Ssh',                'asg/asg-jumpbox',   'asg/asg-ssh']
    AllowSshFromComputeIn       : ['330', 'Inbound', 'Allow', 'Tcp', 'Ssh',                'subnet/compute',    'asg/asg-ssh']
    AllowSshFromDeployerIn      : ['340', 'Inbound', 'Allow', 'Tcp', 'Ssh',                'asg/asg-deployer',  'asg/asg-ssh'] # Only in a deployer VM scenario
    AllowDeployerToPackerSshIn  : ['350', 'Inbound', 'Allow', 'Tcp', 'Ssh',                'asg/asg-deployer',  'subnet/admin'] # Only in a deployer VM scenario
    AllowSshToComputeIn         : ['360', 'Inbound', 'Allow', 'Tcp', 'Ssh',                'asg/asg-ssh',       'subnet/compute']
    AllowSshComputeComputeIn    : ['365', 'Inbound', 'Allow', 'Tcp', 'Ssh',                'subnet/compute',    'subnet/compute']

    # PBS
    AllowPbsIn                  : ['369', 'Inbound', 'Allow', '*',   'Pbs',                'asg/asg-pbs',        'asg/asg-pbs-client']
    AllowPbsClientIn            : ['370', 'Inbound', 'Allow', '*',   'Pbs',                'asg/asg-pbs-client', 'asg/asg-pbs']
    AllowPbsComputeIn           : ['380', 'Inbound', 'Allow', '*',   'Pbs',                'asg/asg-pbs',        'subnet/compute']
    AllowComputePbsClientIn     : ['390', 'Inbound', 'Allow', '*',   'Pbs',                'subnet/compute',     'asg/asg-pbs-client']
    AllowComputePbsIn           : ['400', 'Inbound', 'Allow', '*',   'Pbs',                'subnet/compute',     'asg/asg-pbs']
    AllowComputeComputePbsIn    : ['401', 'Inbound', 'Allow', '*',   'Pbs',                'subnet/compute',     'subnet/compute']

    # SLURM
    AllowComputeSlurmIn         : ['405', 'Inbound', 'Allow', '*',   'Slurmd',             'asg/asg-ondemand',    'subnet/compute']

    # Lustre
    AllowLustreIn               : ['409', 'Inbound', 'Allow', 'Tcp', 'Lustre',             'asg/asg-lustre',        'asg/asg-lustre-client']
    AllowLustreClientIn         : ['410', 'Inbound', 'Allow', 'Tcp', 'Lustre',             'asg/asg-lustre-client', 'asg/asg-lustre']
    AllowLustreClientComputeIn  : ['420', 'Inbound', 'Allow', 'Tcp', 'Lustre',             'subnet/compute',        'asg/asg-lustre']
    AllowRobinhoodIn            : ['430', 'Inbound', 'Allow', 'Tcp', 'Web',                'asg/asg-ondemand',      'asg/asg-robinhood']

    # CycleCloud
    AllowCycleWebIn             : ['440', 'Inbound', 'Allow', 'Tcp', 'Web',                'asg/asg-ondemand',          'asg/asg-cyclecloud']
    AllowCycleClientIn          : ['450', 'Inbound', 'Allow', 'Tcp', 'CycleCloud',         'asg/asg-cyclecloud-client', 'asg/asg-cyclecloud']
    AllowCycleClientComputeIn   : ['460', 'Inbound', 'Allow', 'Tcp', 'CycleCloud',         'subnet/compute',            'asg/asg-cyclecloud']
    AllowCycleServerIn          : ['465', 'Inbound', 'Allow', 'Tcp', 'CycleCloud',         'asg/asg-cyclecloud',        'asg/asg-cyclecloud-client']

    # OnDemand NoVNC
    AllowComputeNoVncIn         : ['470', 'Inbound', 'Allow', 'Tcp', 'NoVnc',              'subnet/compute',            'asg/asg-ondemand']
    AllowNoVncComputeIn         : ['480', 'Inbound', 'Allow', 'Tcp', 'NoVnc',              'asg/asg-ondemand',          'subnet/compute']

    # Telegraf / Grafana
    AllowTelegrafIn             : ['490', 'Inbound', 'Allow', 'Tcp', 'Telegraf',           'asg/asg-telegraf',          'asg/asg-grafana']
    AllowComputeTelegrafIn      : ['500', 'Inbound', 'Allow', 'Tcp', 'Telegraf',           'subnet/compute',            'asg/asg-grafana']
    AllowGrafanaIn              : ['510', 'Inbound', 'Allow', 'Tcp', 'Grafana',            'asg/asg-ondemand',          'asg/asg-grafana']

    # Admin and Deployment
    AllowSocksIn                : ['520', 'Inbound', 'Allow', 'Tcp', 'Socks',              'asg/asg-jumpbox',          'asg/asg-rdp']
    AllowRdpIn                  : ['550', 'Inbound', 'Allow', 'Tcp', 'Rdp',                'asg/asg-jumpbox',          'asg/asg-rdp']

    # Deny all remaining traffic
    DenyVnetInbound             : ['3100', 'Inbound', 'Deny', '*', 'All',                  'tag/VirtualNetwork',       'tag/VirtualNetwork']

    #  _   _   ____     ____        ___    _   _   _____   ____     ___    _   _   _   _   ____  
    # | \ | | / ___|   / ___|  _   / _ \  | | | | |_   _| | __ )   / _ \  | | | | | \ | | |  _ \
    # |  \| | \___ \  | |  _  (_) | | | | | | | |   | |   |  _ \  | | | | | | | | |  \| | | | | |
    # | |\  |  ___) | | |_| |  _  | |_| | | |_| |   | |   | |_) | | |_| | | |_| | | |\  | | |_| |
    # |_| \_| |____/   \____| (_)  \___/   \___/    |_|   |____/   \___/   \___/  |_| \_| |____/
    # AD communication
    AllowAdClientTcpOut         : ['200', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg/asg-ad-client', 'asg/asg-ad']
    AllowAdClientUdpOut         : ['210', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg/asg-ad-client', 'asg/asg-ad']
    AllowAdClientComputeTcpOut  : ['220', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'subnet/compute',    'asg/asg-ad']
    AllowAdClientComputeUdpOut  : ['230', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'subnet/compute',    'asg/asg-ad']
    AllowAdServerTcpOut         : ['240', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg/asg-ad',        'asg/asg-ad-client']
    AllowAdServerUdpOut         : ['250', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg/asg-ad',        'asg/asg-ad-client']
    AllowAdServerComputeTcpOut  : ['260', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg/asg-ad',        'subnet/compute']
    AllowAdServerComputeUdpOut  : ['270', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg/asg-ad',        'subnet/compute']
    AllowAdServerNetappTcpOut   : ['280', 'Outbound', 'Allow', 'Tcp', 'DomainControlerTcp', 'asg/asg-ad',        'subnet/netapp']
    AllowAdServerNetappUdpOut   : ['290', 'Outbound', 'Allow', 'Udp', 'DomainControlerUdp', 'asg/asg-ad',        'subnet/netapp']

    # CycleCloud
    AllowCycleServerOut         : ['300', 'Outbound', 'Allow', 'Tcp', 'CycleCloud',         'asg/asg-cyclecloud',        'asg/asg-cyclecloud-client']
    AllowCycleClientOut         : ['310', 'Outbound', 'Allow', 'Tcp', 'CycleCloud',         'asg/asg-cyclecloud-client', 'asg/asg-cyclecloud']
    AllowComputeCycleClientIn   : ['320', 'Outbound', 'Allow', 'Tcp', 'CycleCloud',         'subnet/compute',            'asg/asg-cyclecloud']
    AllowCycleWebOut            : ['330', 'Outbound', 'Allow', 'Tcp', 'Web',                'asg/asg-ondemand',          'asg/asg-cyclecloud']

    # PBS
    AllowPbsOut                 : ['340', 'Outbound', 'Allow', '*',   'Pbs',                'asg/asg-pbs',        'asg/asg-pbs-client']
    AllowPbsClientOut           : ['350', 'Outbound', 'Allow', '*',   'Pbs',                'asg/asg-pbs-client', 'asg/asg-pbs']
    AllowPbsComputeOut          : ['360', 'Outbound', 'Allow', '*',   'Pbs',                'asg/asg-pbs',        'subnet/compute']
    AllowPbsClientComputeOut    : ['370', 'Outbound', 'Allow', '*',   'Pbs',                'subnet/compute',     'asg/asg-pbs']
    AllowComputePbsClientOut    : ['380', 'Outbound', 'Allow', '*',   'Pbs',                'subnet/compute',     'asg/asg-pbs-client']
    AllowComputeComputePbsOut   : ['381', 'Outbound', 'Allow', '*',   'Pbs',                'subnet/compute',     'subnet/compute']

    # SLURM
    AllowSlurmComputeOut        : ['385', 'Outbound', 'Allow', '*',   'Slurmd',             'asg/asg-ondemand',        'subnet/compute']

    # Lustre
    AllowLustreOut              : ['390', 'Outbound', 'Allow', 'Tcp', 'Lustre',             'asg/asg-lustre',           'asg/asg-lustre-client']
    AllowLustreClientOut        : ['400', 'Outbound', 'Allow', 'Tcp', 'Lustre',             'asg/asg-lustre-client',    'asg/asg-lustre']
    #AllowLustreComputeOut       : ['410', 'Outbound', 'Allow', 'Tcp', 'Lustre',             'asg/asg-lustre',           'subnet/compute']
    AllowLustreClientComputeOut : ['420', 'Outbound', 'Allow', 'Tcp', 'Lustre',             'subnet/compute',           'asg/asg-lustre']
    AllowRobinhoodOut           : ['430', 'Outbound', 'Allow', 'Tcp', 'Web',                'asg/asg-ondemand',         'asg/asg-robinhood']

    # NFS
    AllowNfsOut                 : ['440', 'Outbound', 'Allow', '*',   'Nfs',                'asg/asg-nfs-client',       'subnet/netapp']
    AllowNfsComputeOut          : ['450', 'Outbound', 'Allow', '*',   'Nfs',                'subnet/compute',           'subnet/netapp']

    # Telegraf / Grafana
    AllowTelegrafOut            : ['460', 'Outbound', 'Allow', 'Tcp', 'Telegraf',           'asg/asg-telegraf',          'asg/asg-grafana']
    AllowComputeTelegrafOut     : ['470', 'Outbound', 'Allow', 'Tcp', 'Telegraf',           'subnet/compute',            'asg/asg-grafana']
    AllowGrafanaOut             : ['480', 'Outbound', 'Allow', 'Tcp', 'Grafana',            'asg/asg-ondemand',          'asg/asg-grafana']

    # SSH internal rules
    AllowSshFromJumpboxOut      : ['490', 'Outbound', 'Allow', 'Tcp', 'Ssh',                'asg/asg-jumpbox',          'asg/asg-ssh']
    AllowSshComputeOut          : ['500', 'Outbound', 'Allow', 'Tcp', 'Ssh',                'asg/asg-ssh',              'subnet/compute']
    AllowSshDeployerOut         : ['510', 'Outbound', 'Allow', 'Tcp', 'Ssh',                'asg/asg-deployer',         'asg/asg-ssh']
    AllowSshDeployerPackerOut   : ['520', 'Outbound', 'Allow', 'Tcp', 'Ssh',                'asg/asg-deployer',         'subnet/admin']
    AllowSshFromComputeOut      : ['530', 'Outbound', 'Allow', 'Tcp', 'Ssh',                'subnet/compute',           'asg/asg-ssh']
    AllowSshComputeComputeOut   : ['540', 'Outbound', 'Allow', 'Tcp', 'Ssh',                'subnet/compute',           'subnet/compute']

    # OnDemand NoVNC
    AllowComputeNoVncOut        : ['550', 'Outbound', 'Allow', 'Tcp', 'NoVnc',              'subnet/compute',            'asg/asg-ondemand']
    AllowNoVncComputeOut        : ['560', 'Outbound', 'Allow', 'Tcp', 'NoVnc',              'asg/asg-ondemand',          'subnet/compute']

    # Admin and Deployment
    AllowRdpOut                 : ['570', 'Outbound', 'Allow', 'Tcp', 'Rdp',                'asg/asg-jumpbox',          'asg/asg-rdp']
    AllowSocksOut               : ['580', 'Outbound', 'Allow', 'Tcp', 'Socks',              'asg/asg-jumpbox',          'asg/asg-rdp']
    AllowDnsOut                 : ['590', 'Outbound', 'Allow', '*',   'Dns',                'tag/VirtualNetwork',       'tag/VirtualNetwork']

    # Deny all remaining traffic and allow Internet access
    AllowInternetOutBound       : ['3000', 'Outbound', 'Allow', 'Tcp', 'All',               'tag/VirtualNetwork',       'tag/Internet']
    DenyVnetOutbound            : ['3100', 'Outbound', 'Deny',  '*',   'All',               'tag/VirtualNetwork',       'tag/VirtualNetwork']

internet_nsg_rules:
    AllowInternetSshIn          : ['200', 'Inbound', 'Allow', 'Tcp', 'Public_Ssh',         'tag/Internet', 'asg/asg-jumpbox'] # Only when using a PIP
    AllowInternetHttpIn         : ['210', 'Inbound', 'Allow', 'Tcp', 'Web',                'tag/Internet', 'asg/asg-ondemand'] # Only when using a PIP

hub_nsg_rules :
    AllowHubSshIn               : ['200', 'Inbound', 'Allow', 'Tcp', 'Public_Ssh',               'tag/VirtualNetwork', 'asg/asg-jumpbox']
    AllowHubHttpIn              : ['210', 'Inbound', 'Allow', 'Tcp', 'Web',                      'tag/VirtualNetwork', 'asg/asg-ondemand']

bastion_nsg_rules:
    AllowBastionIn              : ['530', 'Inbound', 'Allow', 'Tcp', 'Bastion',            'subnet/bastion',           'tag/VirtualNetwork']

gateway_nsg_rules:
    AllowInternalWebUsersIn     : ['540', 'Inbound', 'Allow', 'Tcp', 'Web',                'subnet/gateway',           'asg/asg-ondemand']

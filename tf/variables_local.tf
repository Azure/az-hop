locals {
    # azurerm_client_config contains empty values for Managed Identity so use variables instead
    tenant_id = var.tenant_id
    logged_user_objectId = var.logged_user_objectId

    # config files and directories
    packer_root_dir = "${path.cwd}/packer"
    playbook_root_dir = "${path.cwd}/playbooks"
    playbooks_template_dir = "${path.root}/templates"
    configuration_file="${path.cwd}/config.yml"
    configuration_yml=yamldecode(file(local.configuration_file))
    
    # Load parameters from the configuration file
    location = local.configuration_yml["location"]
    resource_group = local.configuration_yml["resource_group"]
    extra_tags = try(local.configuration_yml["tags"], null)
    common_tags = {
        CreatedBy = var.CreatedBy
        CreatedOn = timestamp()
    }

    # Create the RG if not using an existing RG and (creating a VNET or when reusing a VNET in another resource group)
    use_existing_rg = try(local.configuration_yml["use_existing_rg"], false)
    create_rg = (!local.use_existing_rg) && (local.create_vnet || try(split("/", local.vnet_id)[4], local.resource_group) != local.resource_group)

    # ANF
    create_anf = try(local.configuration_yml["anf"]["homefs_size_tb"] > 0, false) || try(local.configuration_yml["homefs_size_tb"] > 0, false)

    homefs_size_tb = try(local.configuration_yml["anf"]["homefs_size_tb"], try(local.configuration_yml["homefs_size_tb"], 4))
    homefs_service_level = try(local.configuration_yml["anf"]["homefs_service_level"], try(local.configuration_yml["homefs_service_level"], "Standard"))
    anf_dual_protocol = try(local.configuration_yml["anf"]["dual_protocol"], try(local.configuration_yml["dual_protocol"], false))

    homedir_mountpoint = try(local.configuration_yml["mounts"]["home"]["mountpoint"], try(local.configuration_yml["homedir_mountpoint"], "/anfhome"))

    admin_username = local.configuration_yml["admin_user"]
    key_vault_readers = try(local.configuration_yml["key_vault_readers"], null)

    # Lustre
    lustre_archive_account = try(local.configuration_yml["lustre"]["hsm"]["storage_account"], null)
    lustre_rbh_sku = try(local.configuration_yml["lustre"]["rbh_sku"], "Standard_D8d_v4")
    lustre_mds_sku = try(local.configuration_yml["lustre"]["mds_sku"], "Standard_D8d_v4")
    lustre_oss_sku = try(local.configuration_yml["lustre"]["oss_sku"], "Standard_D32d_v4")
    lustre_oss_count = try(local.configuration_yml["lustre"]["oss_count"], 2)

    # Winviz
    create_winviz = try(local.configuration_yml["winviz"].create, false)

    # Slurm Accounting Database
    slurm_accounting = try(local.configuration_yml["slurm"].accounting_enabled, false)
    slurm_accounting_admin_user = "sqladmin"
    
    # VNET
    create_vnet = try(length(local.vnet_id) > 0 ? false : true, true)
    vnet_id = try(local.configuration_yml["network"]["vnet"]["id"], null)

    # VNET Peering
    create_peering = try(length(local.peering_vnet_name) > 0 ? 1 : 0, 0)
    peering_vnet_name = try(local.configuration_yml["network"]["peering"]["vnet_name"], null)
    peering_vnet_resource_group = try(local.configuration_yml["network"]["peering"]["vnet_resource_group"], null)

    # Lockdown scenario
    locked_down_network = try(local.configuration_yml["locked_down_network"]["enforce"], false)
    grant_access_from   = try(local.configuration_yml["locked_down_network"]["grant_access_from"], [])
    allow_public_ip = try(local.configuration_yml["locked_down_network"]["public_ip"], true)

    # subnets
    subnets = {
        ad = "ad",
        frontend = "frontend",
        admin = "admin",
        netapp = "netapp",
        bastion = "AzureBastionSubnet",
        gateway = "GatewaySubnet",
        compute = "compute"
    }

    # Create subnet if required. If not specified create only if vnet is created
    create_frontend_subnet = try(local.configuration_yml["network"]["vnet"]["subnets"]["frontend"]["create"], local.create_vnet )
    create_admin_subnet    = try(local.configuration_yml["network"]["vnet"]["subnets"]["admin"]["create"], local.create_vnet )
    create_netapp_subnet   = try(local.configuration_yml["network"]["vnet"]["subnets"]["netapp"]["create"], local.create_vnet )
    create_ad_subnet       = try(local.configuration_yml["network"]["vnet"]["subnets"]["ad"]["create"], local.create_vnet )
    create_compute_subnet  = try(local.configuration_yml["network"]["vnet"]["subnets"]["compute"]["create"], local.create_vnet )
    create_bastion_subnet  = try(local.configuration_yml["network"]["vnet"]["subnets"]["bastion"]["create"], local.create_vnet )
    create_gateway_subnet  = try(local.configuration_yml["network"]["vnet"]["subnets"]["gateway"]["create"], local.create_vnet )

    # Application Security Groups
    create_nsg = try(local.configuration_yml["network"]["create_nsg"], local.create_vnet )
    default_asgs = ["asg-ssh", "asg-rdp", "asg-jumpbox", "asg-ad", "asg-ad-client", "asg-lustre", "asg-lustre-client", "asg-pbs", "asg-pbs-client", "asg-cyclecloud", "asg-cyclecloud-client", "asg-nfs-client", "asg-telegraf", "asg-grafana", "asg-robinhood", "asg-ondemand", "asg-deployer"]
    asgs = { for v in local.default_asgs : v => v }
    empty_array = []
    empty_map = { for v in local.empty_array : v => v }

    # VM name to list of ASGs associations
    asg_associations = {
        ad        = ["asg-ad", "asg-rdp"]
        ccportal  = ["asg-ssh", "asg-cyclecloud", "asg-telegraf", "asg-ad-client"]
        grafana   = ["asg-ssh", "asg-grafana", "asg-ad-client", "asg-telegraf", "asg-nfs-client"]
        jumpbox   = ["asg-ssh", "asg-jumpbox", "asg-ad-client", "asg-telegraf", "asg-nfs-client"]
        lustre    = ["asg-ssh", "asg-lustre", "asg-lustre-client", "asg-telegraf"]
        ondemand  = ["asg-ssh", "asg-ondemand", "asg-ad-client", "asg-nfs-client", "asg-pbs-client", "asg-lustre-client", "asg-telegraf"]
        robinhood = ["asg-ssh", "asg-robinhood", "asg-lustre-client", "asg-telegraf"]
        scheduler = ["asg-ssh", "asg-pbs", "asg-ad-client", "asg-cyclecloud-client", "asg-nfs-client", "asg-telegraf"]
        winviz    = ["asg-ad-client", "asg-rdp"]
    }

    # Open ports for NSG TCP rules
    # ANF and SMB https://docs.microsoft.com/en-us/azure/azure-netapp-files/create-active-directory-connections
    nsg_destination_ports = {
        All = ["0-65535"]
        Bastion = ["22", "3389"]
        Web = ["443", "80"]
        Ssh    = ["22"]
        Socks = ["5985"]
        # DNS, Kerberos, RpcMapper, Ldap, Smb, KerberosPass, LdapSsl, LdapGc, LdapGcSsl, AD Web Services, RpcSam
        DomainControlerTcp = ["53", "88", "135", "389", "445", "464", "686", "3268", "3269", "9389", "49152-65535"]
        # DNS, Kerberos, W32Time, NetBIOS, Ldap, KerberosPass, LdapSsl
        DomainControlerUdp = ["53", "88", "123", "138", "389", "464", "686"]
        # Web, NoVNC, WebSockify
        NoVnc = ["80", "443", "5900-5910", "61001-61010"]
        Dns = ["53"]
        Rdp = ["3389"]
        Pbs = ["6200", "15001-15009", "17001", "32768-61000", "6817-6819"]
        Slurmd = ["6818"]
        Lustre = ["635", "988"]
        Nfs = ["111", "635", "2049", "4045", "4046"]
        Telegraf = ["8086"]
        Grafana = ["3000"]
        # HTTPS, AMQP
        CycleCloud = ["9443", "5672"],
        # MySQL
        MySQL = ["3306", "33060"]
    }

    # Array of NSG rules to be applied on the common NSG
    # NsgRuleName = [priority, direction, access, protocol, destination_port_range, source, destination]
    #   - priority               : integer value from 100 to 4096
    #   - direction              : Inbound, Outbound
    #   - access                 : Allow, Deny
    #   - protocol               : tcp, udp, *
    #   - destination_port_range : name of one of the nsg_destination_ports defined above
    #   - source                 : asg/<asg-name>, subnet/<subnet-name>, tag/<tag-name>. tag-name = any Azure tags like Internet, VirtualNetwork, AzureLoadBalancer, ...
    #   - destination            : same as source
    nsg_rules = {
        # ================================================================================================================================================================
        #                          ###
        #                           #     #    #  #####    ####   #    #  #    #  #####
        #                           #     ##   #  #    #  #    #  #    #  ##   #  #    #
        #                           #     # #  #  #####   #    #  #    #  # #  #  #    #
        #                           #     #  # #  #    #  #    #  #    #  #  # #  #    #
        #                           #     #   ##  #    #  #    #  #    #  #   ##  #    #
        #                          ###    #    #  #####    ####    ####   #    #  #####
        # ================================================================================================================================================================
        # Public Inbound 
        AllowInternetSshIn          = ["200", "Inbound", "Allow", "tcp", "Ssh",                "tag/Internet", "asg/asg-jumpbox"], # Only when using a PIP
        AllowInternetHttpIn         = ["210", "Inbound", "Allow", "tcp", "Web",                "tag/Internet", "asg/asg-ondemand"], # Only when using a PIP

        # AD communication
        AllowAdServerTcpIn          = ["220", "Inbound", "Allow", "tcp", "DomainControlerTcp", "asg/asg-ad",        "asg/asg-ad-client"],
        AllowAdServerUdpIn          = ["230", "Inbound", "Allow", "udp", "DomainControlerUdp", "asg/asg-ad",        "asg/asg-ad-client"],
        AllowAdClientTcpIn          = ["240", "Inbound", "Allow", "tcp", "DomainControlerTcp", "asg/asg-ad-client", "asg/asg-ad"],
        AllowAdClientUdpIn          = ["250", "Inbound", "Allow", "udp", "DomainControlerUdp", "asg/asg-ad-client", "asg/asg-ad"],
        AllowAdServerComputeTcpIn   = ["260", "Inbound", "Allow", "tcp", "DomainControlerTcp", "asg/asg-ad",        "subnet/compute"],
        AllowAdServerComputeUdpIn   = ["270", "Inbound", "Allow", "udp", "DomainControlerUdp", "asg/asg-ad",        "subnet/compute"],
        AllowAdClientComputeTcpIn   = ["280", "Inbound", "Allow", "tcp", "DomainControlerTcp", "subnet/compute",    "asg/asg-ad"],
        AllowAdClientComputeUdpIn   = ["290", "Inbound", "Allow", "udp", "DomainControlerUdp", "subnet/compute",    "asg/asg-ad"],
        AllowAdServerNetappTcpIn    = ["300", "Inbound", "Allow", "tcp", "DomainControlerTcp", "subnet/netapp",      "asg/asg-ad"],
        AllowAdServerNetappUdpIn    = ["310", "Inbound", "Allow", "udp", "DomainControlerUdp", "subnet/netapp",      "asg/asg-ad"],

        # SSH internal rules
        AllowSshFromJumpboxIn       = ["320", "Inbound", "Allow", "tcp", "Ssh",                "asg/asg-jumpbox",   "asg/asg-ssh"],
        AllowSshFromComputeIn       = ["330", "Inbound", "Allow", "tcp", "Ssh",                "subnet/compute",    "asg/asg-ssh"],
        AllowSshFromDeployerIn      = ["340", "Inbound", "Allow", "tcp", "Ssh",                "asg/asg-deployer",  "asg/asg-ssh"], # Only in a deployer VM scenario
        AllowDeployerToPackerSshIn  = ["350", "Inbound", "Allow", "tcp", "Ssh",                "asg/asg-deployer",  "subnet/admin"], # Only in a deployer VM scenario
        AllowSshToComputeIn         = ["360", "Inbound", "Allow", "tcp", "Ssh",                "asg/asg-ssh",       "subnet/compute"],
        AllowSshComputeComputeIn    = ["365", "Inbound", "Allow", "tcp", "Ssh",                "subnet/compute",    "subnet/compute"],

        # PBS
        AllowPbsIn                  = ["369", "Inbound", "Allow", "*",   "Pbs",                "asg/asg-pbs",        "asg/asg-pbs-client"],
        AllowPbsClientIn            = ["370", "Inbound", "Allow", "*",   "Pbs",                "asg/asg-pbs-client", "asg/asg-pbs"],
        AllowPbsComputeIn           = ["380", "Inbound", "Allow", "*",   "Pbs",                "asg/asg-pbs",        "subnet/compute"],
        AllowComputePbsClientIn     = ["390", "Inbound", "Allow", "*",   "Pbs",                "subnet/compute",     "asg/asg-pbs-client"],
        AllowComputePbsIn           = ["400", "Inbound", "Allow", "*",   "Pbs",                "subnet/compute",     "asg/asg-pbs"],
        AllowComputeComputePbsIn    = ["401", "Inbound", "Allow", "*",   "Pbs",                "subnet/compute",     "subnet/compute"],

        # SLURM
        AllowComputeSlurmIn         = ["405", "Inbound", "Allow", "*",   "Slurmd",             "asg/asg-ondemand",    "subnet/compute"],

        # Lustre
        AllowLustreIn               = ["409", "Inbound", "Allow", "tcp", "Lustre",             "asg/asg-lustre",        "asg/asg-lustre-client"],
        AllowLustreClientIn         = ["410", "Inbound", "Allow", "tcp", "Lustre",             "asg/asg-lustre-client", "asg/asg-lustre"],
        AllowLustreClientComputeIn  = ["420", "Inbound", "Allow", "tcp", "Lustre",             "subnet/compute",        "asg/asg-lustre"],
        AllowRobinhoodIn            = ["430", "Inbound", "Allow", "tcp", "Web",                "asg/asg-ondemand",      "asg/asg-robinhood"],

        # CycleCloud
        AllowCycleWebIn             = ["440", "Inbound", "Allow", "tcp", "Web",                "asg/asg-ondemand",          "asg/asg-cyclecloud"],
        AllowCycleClientIn          = ["450", "Inbound", "Allow", "tcp", "CycleCloud",         "asg/asg-cyclecloud-client", "asg/asg-cyclecloud"],
        AllowCycleClientComputeIn   = ["460", "Inbound", "Allow", "tcp", "CycleCloud",         "subnet/compute",            "asg/asg-cyclecloud"],
        AllowCycleServerIn          = ["465", "Inbound", "Allow", "tcp", "CycleCloud",         "asg/asg-cyclecloud",        "asg/asg-cyclecloud-client"],

        # OnDemand NoVNC
        AllowComputeNoVncIn         = ["470", "Inbound", "Allow", "tcp", "NoVnc",              "subnet/compute",            "asg/asg-ondemand"],
        AllowNoVncComputeIn         = ["480", "Inbound", "Allow", "tcp", "NoVnc",              "asg/asg-ondemand",          "subnet/compute"],

        # Telegraf / Grafana
        AllowTelegrafIn             = ["490", "Inbound", "Allow", "tcp", "Telegraf",           "asg/asg-telegraf",          "asg/asg-grafana"],
        AllowComputeTelegrafIn      = ["500", "Inbound", "Allow", "tcp", "Telegraf",           "subnet/compute",            "asg/asg-grafana"],
        AllowGrafanaIn              = ["510", "Inbound", "Allow", "tcp", "Grafana",            "asg/asg-ondemand",          "asg/asg-grafana"],

        # Admin and Deployment
        AllowSocksIn                = ["520", "Inbound", "Allow", "tcp", "Socks",              "asg/asg-jumpbox",          "asg/asg-rdp"],
        AllowBastionIn              = ["530", "Inbound", "Allow", "tcp", "Bastion",            "subnet/bastion",           "tag/VirtualNetwork"],
        AllowInternalWebUsersIn     = ["540", "Inbound", "Allow", "tcp", "Web",                "subnet/gateway",           "asg/asg-ondemand"],
        AllowRdpIn                  = ["550", "Inbound", "Allow", "tcp", "Rdp",                "asg/asg-jumpbox",          "asg/asg-rdp"],

        # Deny all remaining traffic
        DenyVnetInbound             = ["3100", "Inbound", "Deny", "*", "All",                  "tag/VirtualNetwork",       "tag/VirtualNetwork"],

        # ================================================================================================================================================================
        #                            #######
        #                            #     #  #    #   #####  #####    ####   #    #  #    #  #####
        #                            #     #  #    #     #    #    #  #    #  #    #  ##   #  #    #
        #                            #     #  #    #     #    #####   #    #  #    #  # #  #  #    #
        #                            #     #  #    #     #    #    #  #    #  #    #  #  # #  #    #
        #                            #     #  #    #     #    #    #  #    #  #    #  #   ##  #    #
        #                            #######   ####      #    #####    ####    ####   #    #  #####
        # ================================================================================================================================================================
        # AD communication
        AllowAdClientTcpOut         = ["200", "Outbound", "Allow", "tcp", "DomainControlerTcp", "asg/asg-ad-client", "asg/asg-ad"],
        AllowAdClientUdpOut         = ["210", "Outbound", "Allow", "udp", "DomainControlerUdp", "asg/asg-ad-client", "asg/asg-ad"],
        AllowAdClientComputeTcpOut  = ["220", "Outbound", "Allow", "tcp", "DomainControlerTcp", "subnet/compute",    "asg/asg-ad"],
        AllowAdClientComputeUdpOut  = ["230", "Outbound", "Allow", "udp", "DomainControlerUdp", "subnet/compute",    "asg/asg-ad"],
        AllowAdServerTcpOut         = ["240", "Outbound", "Allow", "tcp", "DomainControlerTcp", "asg/asg-ad",        "asg/asg-ad-client"],
        AllowAdServerUdpOut         = ["250", "Outbound", "Allow", "udp", "DomainControlerUdp", "asg/asg-ad",        "asg/asg-ad-client"],
        AllowAdServerComputeTcpOut  = ["260", "Outbound", "Allow", "tcp", "DomainControlerTcp", "asg/asg-ad",        "subnet/compute"],
        AllowAdServerComputeUdpOut  = ["270", "Outbound", "Allow", "udp", "DomainControlerUdp", "asg/asg-ad",        "subnet/compute"],
        AllowAdServerNetappTcpOut   = ["280", "Outbound", "Allow", "tcp", "DomainControlerTcp", "asg/asg-ad",        "subnet/netapp"],
        AllowAdServerNetappUdpOut   = ["290", "Outbound", "Allow", "udp", "DomainControlerUdp", "asg/asg-ad",        "subnet/netapp"],

        # CycleCloud
        AllowCycleServerOut         = ["300", "Outbound", "Allow", "tcp", "CycleCloud",         "asg/asg-cyclecloud",        "asg/asg-cyclecloud-client"],
        AllowCycleClientOut         = ["310", "Outbound", "Allow", "tcp", "CycleCloud",         "asg/asg-cyclecloud-client", "asg/asg-cyclecloud"],
        AllowComputeCycleClientIn   = ["320", "Outbound", "Allow", "tcp", "CycleCloud",         "subnet/compute",            "asg/asg-cyclecloud"],
        AllowCycleWebOut            = ["330", "Outbound", "Allow", "tcp", "Web",                "asg/asg-ondemand",          "asg/asg-cyclecloud"],

        # PBS
        AllowPbsOut                 = ["340", "Outbound", "Allow", "*",   "Pbs",                "asg/asg-pbs",        "asg/asg-pbs-client"],
        AllowPbsClientOut           = ["350", "Outbound", "Allow", "*",   "Pbs",                "asg/asg-pbs-client", "asg/asg-pbs"],
        AllowPbsComputeOut          = ["360", "Outbound", "Allow", "*",   "Pbs",                "asg/asg-pbs",        "subnet/compute"],
        AllowPbsClientComputeOut    = ["370", "Outbound", "Allow", "*",   "Pbs",                "subnet/compute",     "asg/asg-pbs"],
        AllowComputePbsClientOut    = ["380", "Outbound", "Allow", "*",   "Pbs",                "subnet/compute",     "asg/asg-pbs-client"],
        AllowComputeComputePbsOut   = ["381", "Outbound", "Allow", "*",   "Pbs",                "subnet/compute",     "subnet/compute"],

        # SLURM
        AllowSlurmComputeOut        = ["385", "Outbound", "Allow", "*",   "Slurmd",             "asg/asg-ondemand",        "subnet/compute"],

        # Lustre
        AllowLustreOut              = ["390", "Outbound", "Allow", "tcp", "Lustre",             "asg/asg-lustre",           "asg/asg-lustre-client"],
        AllowLustreClientOut        = ["400", "Outbound", "Allow", "tcp", "Lustre",             "asg/asg-lustre-client",    "asg/asg-lustre"],
#        AllowLustreComputeOut       = ["410", "Outbound", "Allow", "tcp", "Lustre",             "asg/asg-lustre",           "subnet/compute"],
        AllowLustreClientComputeOut = ["420", "Outbound", "Allow", "tcp", "Lustre",             "subnet/compute",           "asg/asg-lustre"],
        AllowRobinhoodOut           = ["430", "Outbound", "Allow", "tcp", "Web",                "asg/asg-ondemand",         "asg/asg-robinhood"],

        # NFS
        AllowNfsOut                 = ["440", "Outbound", "Allow", "*",   "Nfs",                "asg/asg-nfs-client",       "subnet/netapp"],
        AllowNfsComputeOut          = ["450", "Outbound", "Allow", "*",   "Nfs",                "subnet/compute",           "subnet/netapp"],

        # Telegraf / Grafana
        AllowTelegrafOut            = ["460", "Outbound", "Allow", "tcp", "Telegraf",           "asg/asg-telegraf",          "asg/asg-grafana"],
        AllowComputeTelegrafOut     = ["470", "Outbound", "Allow", "tcp", "Telegraf",           "subnet/compute",            "asg/asg-grafana"],
        AllowGrafanaOut             = ["480", "Outbound", "Allow", "tcp", "Grafana",            "asg/asg-ondemand",          "asg/asg-grafana"],

        # SSH internal rules
        AllowSshFromJumpboxOut      = ["490", "Outbound", "Allow", "tcp", "Ssh",                "asg/asg-jumpbox",          "asg/asg-ssh"],
        AllowSshComputeOut          = ["500", "Outbound", "Allow", "tcp", "Ssh",                "asg/asg-ssh",              "subnet/compute"],
        AllowSshDeployerOut         = ["510", "Outbound", "Allow", "tcp", "Ssh",                "asg/asg-deployer",         "asg/asg-ssh"],
        AllowSshDeployerPackerOut   = ["520", "Outbound", "Allow", "tcp", "Ssh",                "asg/asg-deployer",         "subnet/admin"],
        AllowSshFromComputeOut      = ["530", "Outbound", "Allow", "tcp", "Ssh",                "subnet/compute",           "asg/asg-ssh"],
        AllowSshComputeComputeOut   = ["540", "Outbound", "Allow", "tcp", "Ssh",                "subnet/compute",           "subnet/compute"],

        # OnDemand NoVNC
        AllowComputeNoVncOut        = ["550", "Outbound", "Allow", "tcp", "NoVnc",              "subnet/compute",            "asg/asg-ondemand"],
        AllowNoVncComputeOut        = ["560", "Outbound", "Allow", "tcp", "NoVnc",              "asg/asg-ondemand",          "subnet/compute"],

        # Admin and Deployment
        AllowRdpOut                 = ["570", "Outbound", "Allow", "tcp", "Rdp",                "asg/asg-jumpbox",          "asg/asg-rdp"],
        AllowSocksOut               = ["580", "Outbound", "Allow", "tcp", "Socks",              "asg/asg-jumpbox",          "asg/asg-rdp"],
        AllowDnsOut                 = ["590", "Outbound", "Allow", "*",   "Dns",                "tag/VirtualNetwork",       "tag/VirtualNetwork"],

        # Deny all remaining traffic and allow Internet access
        AllowInternetOutBound       = ["3000", "Outbound", "Allow", "tcp", "All",               "tag/VirtualNetwork",       "tag/Internet"],
        DenyVnetOutbound            = ["3100", "Outbound", "Deny",  "*",   "All",               "tag/VirtualNetwork",       "tag/VirtualNetwork"],

    }

}
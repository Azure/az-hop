locals {
    # azure environment
    azure_environment = var.AzureEnvironment
    key_vault_suffix = var.KeyVaultSuffix
    blob_storage_suffix = var.BlobStorageSuffix

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

    # Use a linux custom image reference if the linux_base_image is defined and contains ":"
    use_linux_image_reference = try(length(split(":", local.configuration_yml["linux_base_image"])[1])>0, false)
    # Use a lustre custom image reference if the lustre_base_image is defined and contains ":"
    use_lustre_image_reference = try(length(split(":", local.configuration_yml["lustre_base_image"])[1])>0, false)
    # Use a linux custom image reference if the linux_base_image is defined and contains ":"
    use_windows_image_reference = try(length(split(":", local.configuration_yml["windows_base_image"])[1])>0, false)

    linux_base_image_reference = {
        publisher = local.use_linux_image_reference ? split(":", local.configuration_yml["linux_base_image"])[0] : "OpenLogic"
        offer     = local.use_linux_image_reference ? split(":", local.configuration_yml["linux_base_image"])[1] : "CentOS"
        sku       = local.use_linux_image_reference ? split(":", local.configuration_yml["linux_base_image"])[2] : "7_9-gen2"
        version   = local.use_linux_image_reference ? split(":", local.configuration_yml["linux_base_image"])[3] : "latest"
    }
    lustre_base_image_reference = {
        publisher = local.use_lustre_image_reference ? split(":", local.configuration_yml["lustre_base_image"])[0] : "azhpc"
        offer     = local.use_lustre_image_reference ? split(":", local.configuration_yml["lustre_base_image"])[1] : "azurehpc-lustre"
        sku       = local.use_lustre_image_reference ? split(":", local.configuration_yml["lustre_base_image"])[2] : "azurehpc-lustre-2_12"
        version   = local.use_lustre_image_reference ? split(":", local.configuration_yml["lustre_base_image"])[3] : "latest"
    }
    windows_base_image_reference = {
        publisher = local.use_windows_image_reference ? split(":", local.configuration_yml["windows_base_image"])[0] : "MicrosoftWindowsServer"
        offer     = local.use_windows_image_reference ? split(":", local.configuration_yml["windows_base_image"])[1] : "WindowsServer"
        sku       = local.use_windows_image_reference ? split(":", local.configuration_yml["windows_base_image"])[2] : "2016-Datacenter-smalldisk"
        version   = local.use_windows_image_reference ? split(":", local.configuration_yml["windows_base_image"])[3] : "latest"
    }

    # Use a linux custom image id if the linux_base_image is defined and contains "/"
    use_linux_image_id = try(length(split("/", local.configuration_yml["linux_base_image"])[1])>0, false)
    linux_image_id = local.use_linux_image_id ? local.configuration_yml["linux_base_image"] : null

    # Use a lustre custom image id if the lustre_base_image is defined and contains "/"
    use_lustre_image_id = try(length(split("/", local.configuration_yml["lustre_base_image"])[1])>0, false)
    lustre_image_id = local.use_lustre_image_id ? local.configuration_yml["lustre_base_image"] : null

    # Use a windows custom image id if the windows_base_image is defined and contains "/"
    use_windows_image_id = try(length(split("/", local.configuration_yml["windows_base_image"])[1])>0, false)
    windows_image_id = local.use_windows_image_id ? local.configuration_yml["windows_base_image"] : null

    _empty_image_plan = {}
    _linux_base_image_plan = {
        publisher = try(split(":", local.configuration_yml["linux_base_plan"])[0], "")
        product   = try(split(":", local.configuration_yml["linux_base_plan"])[1], "")
        name      = try(split(":", local.configuration_yml["linux_base_plan"])[2], "")
    }
    linux_image_plan = try( length(local._linux_base_image_plan.publisher) > 0 ? local._linux_base_image_plan : local._empty_image_plan, local._empty_image_plan)

    _lustre_base_image_plan = {
        publisher = try(split(":", local.configuration_yml["lustre_base_plan"])[0], "azhpc")
        product   = try(split(":", local.configuration_yml["lustre_base_plan"])[1], "azurehpc-lustre")
        name      = try(split(":", local.configuration_yml["lustre_base_plan"])[2], "azurehpc-lustre-2_12")
    }
    lustre_image_plan = try( length(local._lustre_base_image_plan.publisher) > 0 ? local._lustre_base_image_plan : local._empty_image_plan, local._empty_image_plan)

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

    # Enable Windows Remote Visualization scenarios
    enable_remote_winviz = try(local.configuration_yml["enable_remote_winviz"], false)

    # Queue manager
    queue_manager = try(local.configuration_yml["queue_manager"], "openpbs")

    # Slurm Accounting Database
    slurm_accounting = local.enable_remote_winviz || try(local.configuration_yml["slurm"].accounting_enabled, false)
    slurm_accounting_admin_user = "sqladmin"
    
    # VNET
    create_vnet = try(length(local.vnet_id) > 0 ? false : true, true)
    vnet_id = try(local.configuration_yml["network"]["vnet"]["id"], null)

    # VNET Peering
    vnet_peering = try(tolist(local.configuration_yml["network"]["peering"]), [])

    # Lockdown scenario
    locked_down_network = try(local.configuration_yml["locked_down_network"]["enforce"], false)
    grant_access_from   = try(local.configuration_yml["locked_down_network"]["grant_access_from"], [])
    allow_public_ip     = try(local.configuration_yml["locked_down_network"]["public_ip"], true)
    jumpbox_ssh_port    = try(local.configuration_yml["jumpbox"]["ssh_port"], "22")
    # subnets
    _subnets = {
        ad = "ad",
        frontend = "frontend",
        admin = "admin",
        netapp = "netapp",
        compute = "compute"
    }

    # Create subnet if required. If not specified create only if vnet is created
    create_frontend_subnet = try(local.configuration_yml["network"]["vnet"]["subnets"]["frontend"]["create"], local.create_vnet )
    create_admin_subnet    = try(local.configuration_yml["network"]["vnet"]["subnets"]["admin"]["create"], local.create_vnet )
    create_netapp_subnet   = try(local.configuration_yml["network"]["vnet"]["subnets"]["netapp"]["create"], local.create_vnet )
    create_ad_subnet       = try(local.configuration_yml["network"]["vnet"]["subnets"]["ad"]["create"], local.create_vnet )
    create_compute_subnet  = try(local.configuration_yml["network"]["vnet"]["subnets"]["compute"]["create"], local.create_vnet )

    bastion_subnet = try(local.configuration_yml["network"]["vnet"]["subnets"]["bastion"], null)
    no_bastion_subnet = try(length(local.bastion_subnet) > 0 ? false : true, true )
    create_bastion_subnet  = try(local.bastion_subnet["create"], local.create_vnet )

    gateway_subnet = try(local.configuration_yml["network"]["vnet"]["subnets"]["gateway"], null)
    no_gateway_subnet = try(length(local.gateway_subnet) > 0 ? false : true, true )
    create_gateway_subnet  = try(local.gateway_subnet["create"], local.create_vnet )

    subnets = merge(local._subnets, 
                    local.no_bastion_subnet ? {} : {bastion = "AzureBastionSubnet"},
                    local.no_gateway_subnet ? {} : {gateway = "GatewaySubnet"}
                    )

    # Application Security Groups
    create_nsg = try(local.configuration_yml["network"]["create_nsg"], local.create_vnet )
    # If create NSG then use the local resource group otherwise use the configured one. Default to local resource group
    asg_resource_group = local.create_nsg ? local.resource_group : try(length(local.configuration_yml["network"]["asg"]["resource_group"]) > 0 ? local.configuration_yml["network"]["asg"]["resource_group"] : local.resource_group, local.resource_group )

    _default_asgs = {
        asg-ssh = "asg-ssh"
        asg-rdp = "asg-rdp"
        asg-jumpbox = "asg-jumpbox"
        asg-ad = "asg-ad"
        asg-ad-client = "asg-ad-client"
        asg-lustre = "asg-lustre"
        asg-lustre-client = "asg-lustre-client"
        asg-pbs = "asg-pbs"
        asg-pbs-client = "asg-pbs-client"
        asg-cyclecloud = "asg-cyclecloud"
        asg-cyclecloud-client = "asg-cyclecloud-client"
        asg-nfs-client = "asg-nfs-client"
        asg-telegraf = "asg-telegraf"
        asg-grafana = "asg-grafana"
        asg-robinhood = "asg-robinhood"
        asg-ondemand = "asg-ondemand"
        asg-deployer = "asg-deployer"
        asg-guacamole = "asg-guacamole"
    }
    #asgs = local.create_nsg ? local._default_asgs :  try(local.configuration_yml["network"]["asg"]["names"], local._default_asgs)
    asgs = try(local.configuration_yml["network"]["asg"]["names"], local._default_asgs)
    #asgs = { for v in local.default_asgs : v => v }
    empty_array = []
    empty_map = { for v in local.empty_array : v => v }

    # VM name to list of ASGs associations
    # TODO : Add mapping for names
    asg_associations = {
        ad        = ["asg-ad", "asg-rdp"]
        ccportal  = ["asg-ssh", "asg-cyclecloud", "asg-telegraf", "asg-ad-client"]
        grafana   = ["asg-ssh", "asg-grafana", "asg-ad-client", "asg-telegraf", "asg-nfs-client"]
        jumpbox   = ["asg-ssh", "asg-jumpbox", "asg-ad-client", "asg-telegraf", "asg-nfs-client"]
        lustre    = ["asg-ssh", "asg-lustre", "asg-lustre-client", "asg-telegraf"]
        ondemand  = ["asg-ssh", "asg-ondemand", "asg-ad-client", "asg-nfs-client", "asg-pbs-client", "asg-lustre-client", "asg-telegraf", "asg-guacamole", "asg-cyclecloud-client"]
        robinhood = ["asg-ssh", "asg-robinhood", "asg-lustre-client", "asg-telegraf"]
        scheduler = ["asg-ssh", "asg-pbs", "asg-ad-client", "asg-cyclecloud-client", "asg-nfs-client", "asg-telegraf"]
        guacamole = ["asg-ssh", "asg-ad-client", "asg-telegraf", "asg-nfs-client", "asg-cyclecloud-client"]
    }

    # Open ports for NSG TCP rules
    # ANF and SMB https://docs.microsoft.com/en-us/azure/azure-netapp-files/create-active-directory-connections
    nsg_destination_ports = {
        All = ["0-65535"]
        Bastion = ["22", "3389"]
        Web = ["443", "80"]
        Ssh    = ["22"]
        Public_Ssh = [local.jumpbox_ssh_port]
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
        MySQL = ["3306", "33060"],
        # Guacamole
        Guacamole = ["8080"]
    }

    # Array of NSG rules to be applied on the common NSG
    # NsgRuleName = [priority, direction, access, protocol, destination_port_range, source, destination]
    #   - priority               : integer value from 100 to 4096
    #   - direction              : Inbound, Outbound
    #   - access                 : Allow, Deny
    #   - protocol               : Tcp, Udp, *
    #   - destination_port_range : name of one of the nsg_destination_ports defined above
    #   - source                 : asg/<asg-name>, subnet/<subnet-name>, tag/<tag-name>. tag-name = any Azure tags like Internet, VirtualNetwork, AzureLoadBalancer, ...
    #   - destination            : same as source
    _nsg_rules = {
        # ================================================================================================================================================================
        #                          ###
        #                           #     #    #  #####    ####   #    #  #    #  #####
        #                           #     ##   #  #    #  #    #  #    #  ##   #  #    #
        #                           #     # #  #  #####   #    #  #    #  # #  #  #    #
        #                           #     #  # #  #    #  #    #  #    #  #  # #  #    #
        #                           #     #   ##  #    #  #    #  #    #  #   ##  #    #
        #                          ###    #    #  #####    ####    ####   #    #  #####
        # ================================================================================================================================================================
        # AD communication
        AllowAdServerTcpIn          = ["220", "Inbound", "Allow", "Tcp", "DomainControlerTcp", "asg/asg-ad",        "asg/asg-ad-client"],
        AllowAdServerUdpIn          = ["230", "Inbound", "Allow", "Udp", "DomainControlerUdp", "asg/asg-ad",        "asg/asg-ad-client"],
        AllowAdClientTcpIn          = ["240", "Inbound", "Allow", "Tcp", "DomainControlerTcp", "asg/asg-ad-client", "asg/asg-ad"],
        AllowAdClientUdpIn          = ["250", "Inbound", "Allow", "Udp", "DomainControlerUdp", "asg/asg-ad-client", "asg/asg-ad"],
        AllowAdServerComputeTcpIn   = ["260", "Inbound", "Allow", "Tcp", "DomainControlerTcp", "asg/asg-ad",        "subnet/compute"],
        AllowAdServerComputeUdpIn   = ["270", "Inbound", "Allow", "Udp", "DomainControlerUdp", "asg/asg-ad",        "subnet/compute"],
        AllowAdClientComputeTcpIn   = ["280", "Inbound", "Allow", "Tcp", "DomainControlerTcp", "subnet/compute",    "asg/asg-ad"],
        AllowAdClientComputeUdpIn   = ["290", "Inbound", "Allow", "Udp", "DomainControlerUdp", "subnet/compute",    "asg/asg-ad"],
        AllowAdServerNetappTcpIn    = ["300", "Inbound", "Allow", "Tcp", "DomainControlerTcp", "subnet/netapp",      "asg/asg-ad"],
        AllowAdServerNetappUdpIn    = ["310", "Inbound", "Allow", "Udp", "DomainControlerUdp", "subnet/netapp",      "asg/asg-ad"],

        # SSH internal rules
        AllowSshFromJumpboxIn       = ["320", "Inbound", "Allow", "Tcp", "Ssh",                "asg/asg-jumpbox",   "asg/asg-ssh"],
        AllowSshFromComputeIn       = ["330", "Inbound", "Allow", "Tcp", "Ssh",                "subnet/compute",    "asg/asg-ssh"],
        AllowSshFromDeployerIn      = ["340", "Inbound", "Allow", "Tcp", "Ssh",                "asg/asg-deployer",  "asg/asg-ssh"], # Only in a deployer VM scenario
        AllowDeployerToPackerSshIn  = ["350", "Inbound", "Allow", "Tcp", "Ssh",                "asg/asg-deployer",  "subnet/admin"], # Only in a deployer VM scenario
        AllowSshToComputeIn         = ["360", "Inbound", "Allow", "Tcp", "Ssh",                "asg/asg-ssh",       "subnet/compute"],
        AllowSshComputeComputeIn    = ["365", "Inbound", "Allow", "Tcp", "Ssh",                "subnet/compute",    "subnet/compute"],

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
        AllowLustreIn               = ["409", "Inbound", "Allow", "Tcp", "Lustre",             "asg/asg-lustre",        "asg/asg-lustre-client"],
        AllowLustreClientIn         = ["410", "Inbound", "Allow", "Tcp", "Lustre",             "asg/asg-lustre-client", "asg/asg-lustre"],
        AllowLustreClientComputeIn  = ["420", "Inbound", "Allow", "Tcp", "Lustre",             "subnet/compute",        "asg/asg-lustre"],
        AllowRobinhoodIn            = ["430", "Inbound", "Allow", "Tcp", "Web",                "asg/asg-ondemand",      "asg/asg-robinhood"],

        # CycleCloud
        AllowCycleWebIn             = ["440", "Inbound", "Allow", "Tcp", "Web",                "asg/asg-ondemand",          "asg/asg-cyclecloud"],
        AllowCycleClientIn          = ["450", "Inbound", "Allow", "Tcp", "CycleCloud",         "asg/asg-cyclecloud-client", "asg/asg-cyclecloud"],
        AllowCycleClientComputeIn   = ["460", "Inbound", "Allow", "Tcp", "CycleCloud",         "subnet/compute",            "asg/asg-cyclecloud"],
        AllowCycleServerIn          = ["465", "Inbound", "Allow", "Tcp", "CycleCloud",         "asg/asg-cyclecloud",        "asg/asg-cyclecloud-client"],

        # OnDemand NoVNC
        AllowComputeNoVncIn         = ["470", "Inbound", "Allow", "Tcp", "NoVnc",              "subnet/compute",            "asg/asg-ondemand"],
        AllowNoVncComputeIn         = ["480", "Inbound", "Allow", "Tcp", "NoVnc",              "asg/asg-ondemand",          "subnet/compute"],

        # Telegraf / Grafana
        AllowTelegrafIn             = ["490", "Inbound", "Allow", "Tcp", "Telegraf",           "asg/asg-telegraf",          "asg/asg-grafana"],
        AllowComputeTelegrafIn      = ["500", "Inbound", "Allow", "Tcp", "Telegraf",           "subnet/compute",            "asg/asg-grafana"],
        AllowGrafanaIn              = ["510", "Inbound", "Allow", "Tcp", "Grafana",            "asg/asg-ondemand",          "asg/asg-grafana"],

        # Admin and Deployment
        AllowSocksIn                = ["520", "Inbound", "Allow", "Tcp", "Socks",              "asg/asg-jumpbox",          "asg/asg-rdp"],
        AllowRdpIn                  = ["550", "Inbound", "Allow", "Tcp", "Rdp",                "asg/asg-jumpbox",          "asg/asg-rdp"],

        # Guacamole
#        AllowGuacamoleWebIn         = ["600", "Inbound", "Allow", "Tcp", "Guacamole",           "asg/asg-ondemand",          "asg/asg-guacamole"],
        AllowGuacamoleRdpIn         = ["610", "Inbound", "Allow", "Tcp", "Rdp",                 "asg/asg-guacamole",         "subnet/compute"],

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
        AllowAdClientTcpOut         = ["200", "Outbound", "Allow", "Tcp", "DomainControlerTcp", "asg/asg-ad-client", "asg/asg-ad"],
        AllowAdClientUdpOut         = ["210", "Outbound", "Allow", "Udp", "DomainControlerUdp", "asg/asg-ad-client", "asg/asg-ad"],
        AllowAdClientComputeTcpOut  = ["220", "Outbound", "Allow", "Tcp", "DomainControlerTcp", "subnet/compute",    "asg/asg-ad"],
        AllowAdClientComputeUdpOut  = ["230", "Outbound", "Allow", "Udp", "DomainControlerUdp", "subnet/compute",    "asg/asg-ad"],
        AllowAdServerTcpOut         = ["240", "Outbound", "Allow", "Tcp", "DomainControlerTcp", "asg/asg-ad",        "asg/asg-ad-client"],
        AllowAdServerUdpOut         = ["250", "Outbound", "Allow", "Udp", "DomainControlerUdp", "asg/asg-ad",        "asg/asg-ad-client"],
        AllowAdServerComputeTcpOut  = ["260", "Outbound", "Allow", "Tcp", "DomainControlerTcp", "asg/asg-ad",        "subnet/compute"],
        AllowAdServerComputeUdpOut  = ["270", "Outbound", "Allow", "Udp", "DomainControlerUdp", "asg/asg-ad",        "subnet/compute"],
        AllowAdServerNetappTcpOut   = ["280", "Outbound", "Allow", "Tcp", "DomainControlerTcp", "asg/asg-ad",        "subnet/netapp"],
        AllowAdServerNetappUdpOut   = ["290", "Outbound", "Allow", "Udp", "DomainControlerUdp", "asg/asg-ad",        "subnet/netapp"],

        # CycleCloud
        AllowCycleServerOut         = ["300", "Outbound", "Allow", "Tcp", "CycleCloud",         "asg/asg-cyclecloud",        "asg/asg-cyclecloud-client"],
        AllowCycleClientOut         = ["310", "Outbound", "Allow", "Tcp", "CycleCloud",         "asg/asg-cyclecloud-client", "asg/asg-cyclecloud"],
        AllowComputeCycleClientIn   = ["320", "Outbound", "Allow", "Tcp", "CycleCloud",         "subnet/compute",            "asg/asg-cyclecloud"],
        AllowCycleWebOut            = ["330", "Outbound", "Allow", "Tcp", "Web",                "asg/asg-ondemand",          "asg/asg-cyclecloud"],

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
        AllowLustreOut              = ["390", "Outbound", "Allow", "Tcp", "Lustre",             "asg/asg-lustre",           "asg/asg-lustre-client"],
        AllowLustreClientOut        = ["400", "Outbound", "Allow", "Tcp", "Lustre",             "asg/asg-lustre-client",    "asg/asg-lustre"],
#        AllowLustreComputeOut       = ["410", "Outbound", "Allow", "Tcp", "Lustre",             "asg/asg-lustre",           "subnet/compute"],
        AllowLustreClientComputeOut = ["420", "Outbound", "Allow", "Tcp", "Lustre",             "subnet/compute",           "asg/asg-lustre"],
        AllowRobinhoodOut           = ["430", "Outbound", "Allow", "Tcp", "Web",                "asg/asg-ondemand",         "asg/asg-robinhood"],

        # NFS
        AllowNfsOut                 = ["440", "Outbound", "Allow", "*",   "Nfs",                "asg/asg-nfs-client",       "subnet/netapp"],
        AllowNfsComputeOut          = ["450", "Outbound", "Allow", "*",   "Nfs",                "subnet/compute",           "subnet/netapp"],

        # Telegraf / Grafana
        AllowTelegrafOut            = ["460", "Outbound", "Allow", "Tcp", "Telegraf",           "asg/asg-telegraf",          "asg/asg-grafana"],
        AllowComputeTelegrafOut     = ["470", "Outbound", "Allow", "Tcp", "Telegraf",           "subnet/compute",            "asg/asg-grafana"],
        AllowGrafanaOut             = ["480", "Outbound", "Allow", "Tcp", "Grafana",            "asg/asg-ondemand",          "asg/asg-grafana"],

        # SSH internal rules
        AllowSshFromJumpboxOut      = ["490", "Outbound", "Allow", "Tcp", "Ssh",                "asg/asg-jumpbox",          "asg/asg-ssh"],
        AllowSshComputeOut          = ["500", "Outbound", "Allow", "Tcp", "Ssh",                "asg/asg-ssh",              "subnet/compute"],
        AllowSshDeployerOut         = ["510", "Outbound", "Allow", "Tcp", "Ssh",                "asg/asg-deployer",         "asg/asg-ssh"],
        AllowSshDeployerPackerOut   = ["520", "Outbound", "Allow", "Tcp", "Ssh",                "asg/asg-deployer",         "subnet/admin"],
        AllowSshFromComputeOut      = ["530", "Outbound", "Allow", "Tcp", "Ssh",                "subnet/compute",           "asg/asg-ssh"],
        AllowSshComputeComputeOut   = ["540", "Outbound", "Allow", "Tcp", "Ssh",                "subnet/compute",           "subnet/compute"],

        # OnDemand NoVNC
        AllowComputeNoVncOut        = ["550", "Outbound", "Allow", "Tcp", "NoVnc",              "subnet/compute",            "asg/asg-ondemand"],
        AllowNoVncComputeOut        = ["560", "Outbound", "Allow", "Tcp", "NoVnc",              "asg/asg-ondemand",          "subnet/compute"],

        # Admin and Deployment
        AllowRdpOut                 = ["570", "Outbound", "Allow", "Tcp", "Rdp",                "asg/asg-jumpbox",          "asg/asg-rdp"],
        AllowSocksOut               = ["580", "Outbound", "Allow", "Tcp", "Socks",              "asg/asg-jumpbox",          "asg/asg-rdp"],
        AllowDnsOut                 = ["590", "Outbound", "Allow", "*",   "Dns",                "tag/VirtualNetwork",       "tag/VirtualNetwork"],

        # Guacamole
#        AllowGuacamoleWebOut        = ["600", "Outbound", "Allow", "Tcp", "Guacamole",           "asg/asg-ondemand",         "asg/asg-guacamole"],
        AllowGuacamoleRdpOut        = ["610", "Outbound", "Allow", "Tcp", "Rdp",                 "asg/asg-guacamole",         "subnet/compute"],

        # Deny all remaining traffic and allow Internet access
        AllowInternetOutBound       = ["3000", "Outbound", "Allow", "Tcp", "All",               "tag/VirtualNetwork",       "tag/Internet"],
        DenyVnetOutbound            = ["3100", "Outbound", "Deny",  "*",   "All",               "tag/VirtualNetwork",       "tag/VirtualNetwork"],
    }

    internet_nsg_rules = {
        AllowInternetSshIn          = ["200", "Inbound", "Allow", "Tcp", "Public_Ssh",         "tag/Internet", "asg/asg-jumpbox"], # Only when using a PIP
        AllowInternetHttpIn         = ["210", "Inbound", "Allow", "Tcp", "Web",                "tag/Internet", "asg/asg-ondemand"], # Only when using a PIP
    }

    hub_nsg_rules = {
        AllowHubSshIn          = ["200", "Inbound", "Allow", "Tcp", "Public_Ssh",               "tag/VirtualNetwork", "asg/asg-jumpbox"],
        AllowHubHttpIn         = ["210", "Inbound", "Allow", "Tcp", "Web",                      "tag/VirtualNetwork", "asg/asg-ondemand"],
    }

    bastion_nsg_rules = {
        AllowBastionIn              = ["530", "Inbound", "Allow", "Tcp", "Bastion",            "subnet/bastion",           "tag/VirtualNetwork"],
    }

    gateway_nsg_rules = {
        AllowInternalWebUsersIn     = ["540", "Inbound", "Allow", "Tcp", "Web",                "subnet/gateway",           "asg/asg-ondemand"],
    }

    nsg_rules = merge(  local._nsg_rules, 
                        local.no_bastion_subnet ? {} : local.bastion_nsg_rules, 
                        local.no_gateway_subnet ? {} : local.gateway_nsg_rules,
                        local.allow_public_ip ? local.internet_nsg_rules : local.hub_nsg_rules)

}


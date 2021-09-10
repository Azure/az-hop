locals {
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

    # Create the RG if creating a VNET or when reusing a VNET in another resource group
    create_rg = local.create_vnet || try(split("/", local.vnet_id)[4], local.resource_group) != local.resource_group

    # ANF
    homefs_size_tb = try(local.configuration_yml["homefs_size_tb"], 4)
    homefs_service_level = try(local.configuration_yml["homefs_service_level"], "Standard")
    anf_dual_protocol = try(local.configuration_yml["dual_protocol"], false)
    homedir_mountpoint = try(local.configuration_yml["homedir_mountpoint"], "/anfhome")

    admin_username = local.configuration_yml["admin_user"]
    key_vault_readers = try(local.configuration_yml["key_vault_readers"], null)

    # Lustre
    lustre_archive_account = try(local.configuration_yml["lustre"]["hsm"]["storage_account"], null)
    lustre_rbh_sku = try(local.configuration_yml["lustre"]["rhb_sku"], "Standard_D8d_v4")
    lustre_mds_sku = try(local.configuration_yml["lustre"]["mds_sku"], "Standard_D8d_v4")
    lustre_oss_sku = try(local.configuration_yml["lustre"]["oss_sku"], "Standard_D32d_v4")
    lustre_oss_count = try(local.configuration_yml["lustre"]["oss_count"], 2)

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


    # Application Security Groups
    default_asgs = ["asg-ssh", "asg-rdp", "asg-jumpbox", "asg-ad", "asg-ad-client", "asg-lustre", "asg-lustre-client", "asg-pbs", "asg-pbs-client", "asg-cyclecloud", "asg-cyclecloud-client", "asg-nfs-client", "asg-telegraf", "asg-grafana", "asg-robinhood", "asg-ondemand", "asg-chrony"]
    asgs = { for v in local.default_asgs : v => v }
    empty_array = []
    empty_map = { for v in local.empty_array : v => v }

    # VM name to list of ASGs associations
    asg_associations = {
        ad        = ["asg-ad", "asg-rdp"]
        ccportal  = ["asg-ssh", "asg-cyclecloud", "asg-telegraf", "asg-chrony", "asg-ad-client"]
        grafana   = ["asg-ssh", "asg-grafana", "asg-ad-client", "asg-telegraf", "asg-nfs-client", "asg-chrony"]
        jumpbox   = ["asg-ssh", "asg-jumpbox", "asg-ad-client", "asg-telegraf", "asg-nfs-client", "asg-chrony"]
        lustre    = ["asg-ssh", "asg-lustre", "asg-lustre-client", "asg-telegraf", "asg-chrony"]
        ondemand  = ["asg-ssh", "asg-ondemand", "asg-ad-client", "asg-nfs-client", "asg-pbs-client", "asg-lustre-client", "asg-telegraf", "asg-chrony"]
        robinhood = ["asg-ssh", "asg-robinhood", "asg-lustre-client", "asg-telegraf", "asg-chrony"]
        scheduler = ["asg-ssh", "asg-pbs", "asg-ad-client", "asg-cyclecloud-client", "asg-nfs-client", "asg-telegraf", "asg-chrony"]
    }

    # Open ports for NSG TCP rules
    # ANF and SMB https://docs.microsoft.com/en-us/azure/azure-netapp-files/create-active-directory-connections
    nsg_destination_ports = {
        Web = ["443", "80"]
        Ssh    = ["22"]
        Chrony = ["123"]
        Socks = ["5985"]
        # DNS, Kerberos, RpcMapper, Ldap, Smb, KerberosPass, LdapSsl, LdapGc, LdapGcSsl, AD Web Services, RpcSam
        DomainControlerTcp = ["53", "88", "135", "389", "445", "464", "686", "3268", "3269", "9389", "49152-65535"]
        # DNS, Kerberos, W32Time, NetBIOS, Ldap, KerberosPass, LdapSsl
        DomainControlerUdp = ["53", "88", "123", "138", "389", "464", "686"]
        # Web, NoVNC, WebSockify
        NoVnc = ["80", "443", "5900-5910", "61001-61010"]
        Dns = ["53"]
        Rdp = ["3389"]
        Pbs = ["6200", "15001-15009", "17001", "32768-61000"]
        Lustre = ["635", "988"]
        Nfs = ["111", "635", "2049", "4045", "4046"]
        Telegraf = ["8086"]
        Grafana = ["3000"]
        # HTTPS, AMQP
        CycleCloud = ["9443", "5672"]
    }
}
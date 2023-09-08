locals {
    # azure environment
    public_cloud_endpoints = {
        KeyVaultSuffix =  "vault.azure.net"
        BlobStorageSuffix = "blob.core.windows.net"
        FileStorageSuffix = "file.core.windows.net"
        MariaDBPrivateLink = "privatelink.mariadb.database.azure.com"
    }
    usgov_cloud_endpoints = {
        KeyVaultSuffix =  "vault.usgovcloudapi.net"
        BlobStorageSuffix = "blob.core.usgovcloudapi.net"
        FileStorageSuffix = "file.core.usgovcloudapi.net"
        MariaDBPrivateLink = "privatelink.mariadb.database.usgovcloudapi.net"
    }
    azure_endpoints = {
        AZUREPUBLICCLOUD = local.public_cloud_endpoints
        AZUREUSGOVERNMENTCLOUD = local.usgov_cloud_endpoints
    }
    azure_environment = var.AzureEnvironment
    key_vault_suffix = local.azure_endpoints[local.azure_environment].KeyVaultSuffix #var.KeyVaultSuffix
    blob_storage_suffix = local.azure_endpoints[local.azure_environment].BlobStorageSuffix #var.BlobStorageSuffix

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

    # the PUID for telemetry is meant to be unique and identifies azhop, so it should not be changed
    telem_azhop_puid  = "58d16d1a-5b7c-11ed-8042-00155d5d7a47"

    # local to determine if the user chose to disable telemetry of azhop
    optout_telemetry = try(local.configuration_yml["optout_telemetry"], false)

    telem_azhop_name = substr(
        format(
            "pid-%s",
            local.telem_azhop_puid
        ),
        0,
        64
    )

    # empty arm template to create the telemetry resource
    telem_arm_subscription_template_content = <<TEMPLATE
    {
        "$schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {},
        "variables": {},
        "resources": [],
        "outputs": {
            "telemetry": {
                "type": "String",
                "value": "For more information, see https://azure.github.io/az-hop/deploy/telemetry.html"
            }
        }
    }
    TEMPLATE

    # Log Analytics
    create_log_analytics_workspace = try(local.configuration_yml["log_analytics"]["create"], false)
    log_analytics_name = try(local.configuration_yml["log_analytics"]["name"], null)
    log_analytics_resource_group = try(local.configuration_yml["log_analytics"]["resource_group"], null)
    log_analytics_subscription_id = try(local.configuration_yml["log_analytics"]["subscription_id"], data.azurerm_subscription.primary.subscription_id)
    log_analytics_workspace_id = try("/subscriptions/${local.log_analytics_subscription_id}/resourceGroups/${local.log_analytics_resource_group}/providers/Microsoft.OperationalInsights/workspaces/${local.log_analytics_name}", null)
    use_existing_ws = ( !local.create_log_analytics_workspace && local.log_analytics_workspace_id != null )  ? true : false
     
    monitor = ( local.create_log_analytics_workspace || local.use_existing_ws ) ? true : false
    ama_install = try(local.configuration_yml["monitoring"]["azure_monitor_agent"], true) && local.monitor ? true : false
    create_grafana = try(local.configuration_yml["monitoring"]["grafana"], true)

    alert_email = try(local.configuration_yml["alerting"]["admin_email"], "admin.mail@contoso.com")

    #For alerting to be enabled - the analytics workspace needs to be created since log alerts are leveraged. 
    #We also need to ensure that we have an email to send alerts to.  
    create_alerts = local.monitor && local.alert_email != "admin.mail@contoso.com" && try(local.configuration_yml["alerting"]["enabled"], false) ? true : false
    anf_vol_threshold = try(local.configuration_yml["anf"]["alert_threshold"], 80)  # default to 80% if not specified 

    # will be used with a KQL query that checks the free space percentage of local volumes
    # if the user wants to create an alert when local volumes are 80% full, then the free space percentage should be 20%
    local_vol_threshold = 100 - try(local.configuration_yml["alerting"]["local_volume_threshold"], 20) 

    mounts = try(local.configuration_yml["mounts"], {})
    mountpoints =  [ for mount in local.mounts : mount.mountpoint ]
    mountpoints_str = "[ ${join(",", [for mp in local.mountpoints : format("%q", mp)])} ]" //necessary to build generic KQL query on local volumes

    # Active Directory values
    # Updates the assumptions to the possibility that DNS may not point to Active Directory when using the customer provided AD.
    create_ad             = !try(local.configuration_yml["domain"].use_existing_dc, false) && (try(local.configuration_yml["authentication"].user_auth, "ad") == "ad")
    use_existing_ad       = try(local.configuration_yml["domain"].use_existing_dc, false)
    create_dns_records    = local.create_ad || local.use_existing_ad
    domain_name           = local.use_existing_ad ? local.configuration_yml["domain"].name : "hpc.azure"
    domain_join_user      = local.use_existing_ad ? local.configuration_yml["domain"].domain_join_user.username : local.admin_username
    domain_join_password  = local.use_existing_ad ? data.azurerm_key_vault_secret.domain_join_password[0].value : random_password.password.result
    domain_join_ou        = local.use_existing_ad ? local.configuration_yml["domain"].domain_join_ou : "CN=Computers"
    ad_ha                 = try(local.configuration_yml["ad"].high_availability, false)
    domain_controlers     = local.use_existing_ad ? zipmap(local.configuration_yml["domain"].existing_dc_details.domain_controller_names, local.configuration_yml["domain"].existing_dc_details.domain_controller_names) : (local.ad_ha ? {ad="ad", ad2="ad2"} : {ad="ad"})
    ldap_server           = local.use_existing_ad ? local.configuration_yml["domain"].existing_dc_details.domain_controller_names[0]     : "ad"
    private_dns_servers   = local.use_existing_ad ? local.configuration_yml["domain"].existing_dc_details.private_dns_servers            : (local.create_ad ? (local.ad_ha ? [azurerm_network_interface.ad-nic[0].private_ip_address, azurerm_network_interface.ad2-nic[0].private_ip_address] : [azurerm_network_interface.ad-nic[0].private_ip_address]) : [])
    domain_controller_ips = local.use_existing_ad ? local.configuration_yml["domain"].existing_dc_details.domain_controller_ip_addresses : (local.create_ad ? (local.ad_ha ? [azurerm_network_interface.ad-nic[0].private_ip_address, azurerm_network_interface.ad2-nic[0].private_ip_address] : [azurerm_network_interface.ad-nic[0].private_ip_address]) : [])

    # Use a linux custom image reference if the linux_base_image is defined and contains ":"
    use_linux_image_reference = try(length(split(":", local.configuration_yml["linux_base_image"])[1])>0, false)
    # Use a lustre custom image reference if the lustre_base_image is defined and contains ":"
    use_lustre_image_reference = try(length(split(":", local.configuration_yml["lustre_base_image"])[1])>0, false)
    # Use a linux custom image reference if the linux_base_image is defined and contains ":"
    use_windows_image_reference = try(length(split(":", local.configuration_yml["windows_base_image"])[1])>0, false)
    # Use a linux custom image reference if the linux_base_image is defined and contains ":"
    use_cyclecloud_image_reference = try(length(split(":", local.configuration_yml["cyclecloud"]["image"])[1])>0, false)

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
        sku       = local.use_windows_image_reference ? split(":", local.configuration_yml["windows_base_image"])[2] : "2019-Datacenter-smalldisk"
        version   = local.use_windows_image_reference ? split(":", local.configuration_yml["windows_base_image"])[3] : "latest"
    }
    cyclecloud_image_reference = {
        publisher = local.use_cyclecloud_image_reference ? split(":", local.configuration_yml["cyclecloud"]["image"])[0] : "OpenLogic"
        offer     = local.use_cyclecloud_image_reference ? split(":", local.configuration_yml["cyclecloud"]["image"])[1] : "CentOS"
        sku       = local.use_cyclecloud_image_reference ? split(":", local.configuration_yml["cyclecloud"]["image"])[2] : "7_9-gen2"
        version   = local.use_cyclecloud_image_reference ? split(":", local.configuration_yml["cyclecloud"]["image"])[3] : "latest"
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

    # Use a cyclecloud custom image id if the cyclecloud_base_image is defined and contains "/"
    use_cyclecloud_image_id = try(length(split("/", local.configuration_yml["cyclecloud"]["image"])[1])>0, false)
    cyclecloud_image_id = local.use_cyclecloud_image_id ? local.configuration_yml["cyclecloud"]["image"] : null

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

    _cyclecloud_image_plan = {
        publisher = try(split(":", local.configuration_yml["cyclecloud"]["plan"])[0], "")
        product   = try(split(":", local.configuration_yml["cyclecloud"]["plan"])[1], "")
        name      = try(split(":", local.configuration_yml["cyclecloud"]["plan"])[2], "")
    }
    cyclecloud_image_plan = try( length(local._cyclecloud_image_plan.publisher) > 0 ? local._cyclecloud_image_plan : local._empty_image_plan, local._empty_image_plan)


    # Create the RG if not using an existing RG and (creating a VNET or when reusing a VNET in another resource group)
    use_existing_rg = try(local.configuration_yml["use_existing_rg"], false)
    create_rg = (!local.use_existing_rg) && (local.create_vnet || try(split("/", local.vnet_id)[4], local.resource_group) != local.resource_group)

    # ANF
    create_anf = try(local.configuration_yml["anf"]["create"], false)
    anf_size=try(local.configuration_yml["anf"]["homefs_size_tb"], 4)
    anf_service_level = try(local.configuration_yml["anf"]["homefs_service_level"], "Standard")
    anf_dual_protocol = try(local.configuration_yml["anf"]["dual_protocol"], false)

    #Azure Files
    create_nfsfiles = try(local.configuration_yml["azurefiles"]["create"], false)
    azure_files_size= try(local.configuration_yml["azurefiles"]["size_gb"], 1024)

    # Home Directory
    homedir_type = try(local.configuration_yml["mounts"]["home"]["type"], "existing")
    config_nfs_home_ip = local.configuration_yml["mounts"]["home"]["server"]
    config_nfs_home_path = local.configuration_yml["mounts"]["home"]["export"]
    config_nfs_home_opts = local.configuration_yml["mounts"]["home"]["options"]

    homedir_mountpoint = try(local.configuration_yml["mounts"]["home"]["mountpoint"], "/anfhome")

    admin_username = local.configuration_yml["admin_user"]
    key_vault_readers = try(local.configuration_yml["key_vault_readers"], null)

    # Resource names
    scheduler_name = try(local.configuration_yml["scheduler"]["name"], "scheduler")
    ccportal_name = try(local.configuration_yml["cyclecloud"]["name"], "ccportal")
    ondemand_name = try(local.configuration_yml["ondemand"]["name"], "ondemand")
    grafana_name = try(local.configuration_yml["grafana"]["name"], "grafana")
    jumpbox_name = try(local.configuration_yml["jumpbox"]["name"], "jumpbox")
    key_vault_name = try(local.configuration_yml["azure_key_vault"]["name"], format("%s%s", "kv", random_string.resource_postfix.result))
    storage_account_name = try(local.configuration_yml["azure_storage_account"]["name"], "azhop${random_string.resource_postfix.result}")
    mariadb_name = try(local.configuration_yml["database"]["name"], "azhop-${random_string.resource_postfix.result}")

    # Lustre
    lustre_enabled = try(local.configuration_yml["lustre"]["create"], false)
    lustre_archive_account = try(local.configuration_yml["lustre"]["hsm"]["storage_account"], null)
    lustre_rbh_sku = try(local.configuration_yml["lustre"]["rbh_sku"], "Standard_D8d_v4")
    lustre_mds_sku = try(local.configuration_yml["lustre"]["mds_sku"], "Standard_D8d_v4")
    lustre_oss_sku = try(local.configuration_yml["lustre"]["oss_sku"], "Standard_D32d_v4")
    lustre_oss_count = try(local.configuration_yml["lustre"]["oss_count"], local.lustre_enabled ? 2 : 0)

    # Use a jumpbox when defined
    jumpbox_enabled = try(length(local.configuration_yml["jumpbox"]) > 0, false)

    # Queue manager
    queue_manager = try(local.configuration_yml["queue_manager"], "openpbs")

    # Create Database
    create_database  = ( try(local.configuration_yml["slurm"].accounting_enabled, false) ) && (! local.use_existing_database)
    use_existing_database = try(length(local.configuration_yml["database"].fqdn) > 0 ? true : false, false)
    database_user = local.create_database ? "sqladmin" : (local.use_existing_database ? try(local.configuration_yml["database"].user, "") : "")
    mariadb_private_dns_zone = local.azure_endpoints[local.azure_environment].MariaDBPrivateLink

    create_sig = try(local.configuration_yml["image_gallery"]["create"], false)
    
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
        frontend = "frontend",
        admin = "admin",
        netapp = "netapp",
        compute = "compute"
    }

    # Create subnet if required. If not specified create only if vnet is created
    create_frontend_subnet = try(local.configuration_yml["network"]["vnet"]["subnets"]["frontend"]["create"], local.create_vnet )
    create_admin_subnet    = try(local.configuration_yml["network"]["vnet"]["subnets"]["admin"]["create"], local.create_vnet )
    create_netapp_subnet   = try(local.configuration_yml["network"]["vnet"]["subnets"]["netapp"]["create"], local.create_vnet )
    create_compute_subnet  = try(local.configuration_yml["network"]["vnet"]["subnets"]["compute"]["create"], local.create_vnet )

    ad_subnet        = try(local.configuration_yml["network"]["vnet"]["subnets"]["ad"], null)
    no_ad_subnet     = try(length(local.ad_subnet) > 0 ? false : true, true)
    create_ad_subnet = try(local.ad_subnet["create"], (local.create_ad ? local.create_vnet : false))

    bastion_subnet = try(local.configuration_yml["network"]["vnet"]["subnets"]["bastion"], null)
    no_bastion_subnet = try(length(local.bastion_subnet) > 0 ? false : true, true )
    create_bastion_subnet  = try(local.bastion_subnet["create"], local.create_vnet )

    gateway_subnet = try(local.configuration_yml["network"]["vnet"]["subnets"]["gateway"], null)
    no_gateway_subnet = try(length(local.gateway_subnet) > 0 ? false : true, true )
    create_gateway_subnet  = try(local.gateway_subnet["create"], local.create_vnet )

    outbounddns_subnet = try(local.configuration_yml["network"]["vnet"]["subnets"]["outbounddns"], null)
    no_outbounddns_subnet = try(length(local.outbounddns_subnet) > 0 ? false : true, true )
    create_outbounddns_subnet  = try(local.outbounddns_subnet["create"], local.create_vnet ? (local.no_outbounddns_subnet ? false : true) : false )

    dns_forwarders = try(local.configuration_yml["dns"]["forwarders"], [])
    create_dnsfw_rules = length(local.dns_forwarders) > 0 ? true : false

    subnets = merge(local._subnets, 
                    local.no_bastion_subnet ? {} : {bastion = "AzureBastionSubnet"},
                    local.no_gateway_subnet ? {} : {gateway = "GatewaySubnet"},
                    local.no_outbounddns_subnet ? {} : {outbounddns = "outbounddns"}
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
        asg-mariadb-client = "asg-mariadb-client"
    }
    #asgs = local.create_nsg ? local._default_asgs :  try(local.configuration_yml["network"]["asg"]["names"], local._default_asgs)
    asgs = try(local.configuration_yml["network"]["asg"]["names"], local._default_asgs)
    #asgs = { for v in local.default_asgs : v => v }
    empty_array = []
    empty_map = { for v in local.empty_array : v => v }

    # VM name to list of ASGs associations
    # TODO : Add mapping for names
    asg_associations = {
        ad        = ["asg-ad", "asg-rdp", "asg-ad-client"] # asg-ad-client will allow the secondary DC scenario
        ccportal  = ["asg-ssh", "asg-cyclecloud", "asg-telegraf", "asg-ad-client"]
        grafana   = ["asg-ssh", "asg-grafana", "asg-ad-client", "asg-telegraf", "asg-nfs-client"]
        jumpbox   = ["asg-ssh", "asg-jumpbox", "asg-ad-client", "asg-telegraf", "asg-nfs-client"]
        lustre    = ["asg-ssh", "asg-lustre", "asg-lustre-client", "asg-telegraf"]
        ondemand  = ["asg-ssh", "asg-ondemand", "asg-ad-client", "asg-nfs-client", "asg-pbs-client", "asg-lustre-client", "asg-telegraf", "asg-cyclecloud-client", "asg-mariadb-client"]
        robinhood = ["asg-ssh", "asg-robinhood", "asg-lustre-client", "asg-telegraf"]
        scheduler = ["asg-ssh", "asg-pbs", "asg-ad-client", "asg-cyclecloud-client", "asg-nfs-client", "asg-telegraf", "asg-mariadb-client"]
    }

    # Open ports for NSG TCP rules
    # ANF and SMB https://docs.microsoft.com/en-us/azure/azure-netapp-files/create-active-directory-connections
    nsg_destination_ports = {
        All = ["0-65535"]
        Bastion = ["22", "3389"]
        Web = ["443", "80"]
        Ssh    = ["22"]
        Public_Ssh = [local.jumpbox_ssh_port]
        # DNS, Kerberos, RpcMapper, Ldap, Smb, KerberosPass, LdapSsl, LdapGc, LdapGcSsl, AD Web Services, RpcSam
        DomainControlerTcp = ["53", "88", "135", "389", "445", "464", "636", "3268", "3269", "9389", "49152-65535"]
        # DNS, Kerberos, W32Time, NetBIOS, Ldap, KerberosPass, LdapSsl
        DomainControlerUdp = ["53", "88", "123", "138", "389", "464", "636"]
        # Web, NoVNC, WebSockify
        NoVnc = ["80", "443", "5900-5910", "61001-61010"]
        Dns = ["53"]
        Rdp = ["3389"]
        Pbs = ["6200", "15001-15009", "17001", "32768-61000", "6817-6819"]
        Slurmd = ["6818"]
        Lustre = ["635", "988"]
        Nfs = ["111", "635", "2049", "4045", "4046"]
        SMB = ["445"]
        Telegraf = ["8086"]
        Grafana = ["3000"]
        # HTTPS, AMQP
        CycleCloud = ["9443", "5672"],
        # MariaDB
        MariaDB = ["3306", "33060"],
        # WinRM
        WinRM = ["5985", "5986"]
    }

    #Replace the AD ASG with domain controller IP addresses when customer is bringing their own AD
    #use an indexing concept since we can't substitute a list for a string
    ad_nsg_index = local.use_existing_ad ? "ips/dc_ips" : "asg/asg-ad"
    ips = {
        dc_ips = local.domain_controller_ips
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
        AllowAdServerTcpIn        = ["220", "Inbound", "Allow", "Tcp", "DomainControlerTcp", local.ad_nsg_index, "asg/asg-ad-client"],
        AllowAdServerUdpIn        = ["230", "Inbound", "Allow", "Udp", "DomainControlerUdp", local.ad_nsg_index, "asg/asg-ad-client"],
        AllowAdClientTcpIn        = ["240", "Inbound", "Allow", "Tcp", "DomainControlerTcp", "asg/asg-ad-client", local.ad_nsg_index],
        AllowAdClientUdpIn        = ["250", "Inbound", "Allow", "Udp", "DomainControlerUdp", "asg/asg-ad-client", local.ad_nsg_index],
        AllowAdServerComputeTcpIn = ["260", "Inbound", "Allow", "Tcp", "DomainControlerTcp", local.ad_nsg_index, "subnet/compute"],
        AllowAdServerComputeUdpIn = ["270", "Inbound", "Allow", "Udp", "DomainControlerUdp", local.ad_nsg_index, "subnet/compute"],
        AllowAdClientComputeTcpIn = ["280", "Inbound", "Allow", "Tcp", "DomainControlerTcp", "subnet/compute", local.ad_nsg_index],
        AllowAdClientComputeUdpIn = ["290", "Inbound", "Allow", "Udp", "DomainControlerUdp", "subnet/compute", local.ad_nsg_index],
        AllowAdServerNetappTcpIn  = ["300", "Inbound", "Allow", "Tcp", "DomainControlerTcp", "subnet/netapp", local.ad_nsg_index],
        AllowAdServerNetappUdpIn  = ["310", "Inbound", "Allow", "Udp", "DomainControlerUdp", "subnet/netapp", local.ad_nsg_index],

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

        # Admin and Deployment
        AllowWinRMIn                = ["520", "Inbound", "Allow", "Tcp", "WinRM",              "asg/asg-jumpbox",          "asg/asg-rdp"],
        AllowRdpIn                  = ["550", "Inbound", "Allow", "Tcp", "Rdp",                "asg/asg-jumpbox",          "asg/asg-rdp"],

        # MariaDB
        AllowMariaDBIn              = ["700", "Inbound", "Allow", "Tcp", "MariaDB",             "asg/asg-mariadb-client",    "subnet/admin"],

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
        AllowAdClientTcpOut        = ["200", "Outbound", "Allow", "Tcp", "DomainControlerTcp", "asg/asg-ad-client", local.ad_nsg_index],
        AllowAdClientUdpOut        = ["210", "Outbound", "Allow", "Udp", "DomainControlerUdp", "asg/asg-ad-client", local.ad_nsg_index],
        AllowAdClientComputeTcpOut = ["220", "Outbound", "Allow", "Tcp", "DomainControlerTcp", "subnet/compute", local.ad_nsg_index],
        AllowAdClientComputeUdpOut = ["230", "Outbound", "Allow", "Udp", "DomainControlerUdp", "subnet/compute", local.ad_nsg_index],
        AllowAdServerTcpOut        = ["240", "Outbound", "Allow", "Tcp", "DomainControlerTcp", local.ad_nsg_index, "asg/asg-ad-client"],
        AllowAdServerUdpOut        = ["250", "Outbound", "Allow", "Udp", "DomainControlerUdp", local.ad_nsg_index, "asg/asg-ad-client"],
        AllowAdServerComputeTcpOut = ["260", "Outbound", "Allow", "Tcp", "DomainControlerTcp", local.ad_nsg_index, "subnet/compute"],
        AllowAdServerComputeUdpOut = ["270", "Outbound", "Allow", "Udp", "DomainControlerUdp", local.ad_nsg_index, "subnet/compute"],
        AllowAdServerNetappTcpOut  = ["280", "Outbound", "Allow", "Tcp", "DomainControlerTcp", local.ad_nsg_index, "subnet/netapp"],
        AllowAdServerNetappUdpOut  = ["290", "Outbound", "Allow", "Udp", "DomainControlerUdp", local.ad_nsg_index, "subnet/netapp"],

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

        # SMB
        AllowSMBComputeOut          = ["455", "Outbound", "Allow", "*",   "SMB",                "subnet/compute",            "subnet/netapp"],

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
        AllowWinRMOut               = ["580", "Outbound", "Allow", "Tcp", "WinRM",              "asg/asg-jumpbox",          "asg/asg-rdp"],
        AllowDnsOut                 = ["590", "Outbound", "Allow", "*",   "Dns",                "tag/VirtualNetwork",       "tag/VirtualNetwork"],

        # MariaDB
        AllowMariaDBOut             = ["700", "Outbound", "Allow", "Tcp", "MariaDB",             "asg/asg-mariadb-client",    "subnet/admin"],

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
        AllowPackerWinRMIn     = ["560", "Inbound", "Allow", "Tcp", "WinRM",                    "tag/VirtualNetwork", "subnet/compute"],
    }

    bastion_nsg_rules = {
        AllowBastionIn              = ["530", "Inbound", "Allow", "Tcp", "Bastion",            "subnet/bastion",           "tag/VirtualNetwork"],
    }

    gateway_nsg_rules = {
        AllowInternalWebUsersIn     = ["540", "Inbound", "Allow", "Tcp", "Web",                "subnet/gateway",           "asg/asg-ondemand"],
    }

    grafana_nsg_rules = {
        # Telegraf / Grafana
        AllowTelegrafIn             = ["490", "Inbound", "Allow", "Tcp", "Telegraf",           "asg/asg-telegraf",          "asg/asg-grafana"],
        AllowComputeTelegrafIn      = ["500", "Inbound", "Allow", "Tcp", "Telegraf",           "subnet/compute",            "asg/asg-grafana"],
        AllowGrafanaIn              = ["510", "Inbound", "Allow", "Tcp", "Grafana",            "asg/asg-ondemand",          "asg/asg-grafana"],

        # Telegraf / Grafana
        AllowTelegrafOut            = ["460", "Outbound", "Allow", "Tcp", "Telegraf",           "asg/asg-telegraf",          "asg/asg-grafana"],
        AllowComputeTelegrafOut     = ["470", "Outbound", "Allow", "Tcp", "Telegraf",           "subnet/compute",            "asg/asg-grafana"],
        AllowGrafanaOut             = ["480", "Outbound", "Allow", "Tcp", "Grafana",            "asg/asg-ondemand",          "asg/asg-grafana"],
    }

    nsg_rules = merge(  local._nsg_rules, 
                        local.no_bastion_subnet ? {} : local.bastion_nsg_rules, 
                        local.no_gateway_subnet ? {} : local.gateway_nsg_rules,
                        local.allow_public_ip ? local.internet_nsg_rules : local.hub_nsg_rules,
                        local.create_grafana ? local.grafana_nsg_rules : {})

}


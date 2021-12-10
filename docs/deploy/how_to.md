# How To

- [How to use an existing VNET ?](#how-to-use-an-existing-vnet)
  - [Pre-requisities for using an existing VNET](#pre-requisities-for-using-an-existing-vnet)
  - [Creating a standalone VNET for AZ-HOP](#creating-a-standalone-vnet-for-az-hop)
- [How to deploy ANF with Dual protocol ?](#how-to-deploy-anf-with-dual-protocol)
- [How to deploy in a locked down network environment ?](#deploy-in-a-locked-down-network-environment)
- [Disable Public IP scenario](#disable-public-ip-scenario)
- [Use your own SSL certificate](#use-your-own-ssl-certificate)
- [Not deploy ANF](#not-deploy-anf)
- [Use an existing NFS mount point](#use-an-existing-nfs-mount-point)
- [Use Azure Active Directory for MFA](#use-azure-active-directory-for-mfa)

## How to use an existing VNET ?
Using an existing VNET can be done by specifying in the `config.yml` file the VNET ID that needs to be used as shown below.

```yml
network:
  vnet:
    id: /subscriptions/<subscription id>/resourceGroups/<vnet resource group>/providers/Microsoft.Network/virtualNetworks/<vnet name>
```

**azhop** subnet names can be mapped to existing subnets names in the provided vnet by specifying then as below. 
> Note : The same subnet name can be used multiple times if needed.

```yml
network:
  vnet:
    id: /subscriptions/<subscription id>/resourceGroups/<vnet resource group>/providers/Microsoft.Network/virtualNetworks/<vnet name>
    subnets:
      frontend: 
        name: ondemand
      admin:
        name: itonly
      netapp:
        name: storage
      ad:
        name: domaincontroler
      compute:
        name: dynamic
```

### Pre-requisities for using an existing VNET
- There is a need of a minimum of 5 IP addresses for the infrastructure VMs
- Allow enough IP addresses for the Lustre cluster, default being 4 : Robinhood + Lustre + 2*OSS
- Delegate a subnet to Azure NetApp Files like documented [here](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-delegate-subnet)
- Look at the `tf/network_security_group.tf` and `tf/variables_local.tf` to get the list of all ports and rules define bewteen subnets

### Creating a standalone VNET for AZ-HOP
There is a way to easily create a standalone VNET for **azhop** without doing a full deployment by following these steps :
- Create a configuration file with all the required values for creating a VNET
- run the build command specify the *tf/network* subdirectory `./build -a [plan, apply, destroy] -f tf/network`
- Save your config file and create a new one in which you now specify the VNET ID created above
- Build your **azhop** environment

## How to deploy ANF with Dual protocol
When using Windows nodes you may want to use SMB to mount ANF volumes, as a result ANF need to be configure to use dual protocol and the ANF account need to be domain joined. This imply to break out the deployment in two main steps because the Active Directory need to be configured before provisioning ANF. Follow the steps below to deploy ANF with Dual Protocol enabled :

 - Dual protocol must be enabled in the configuration file with this value :

```yml
# dual protocol
dual_protocol: true # true to enable SMB support. false by default
```

- Build the infrastructure and the Active Directory machine :
```bash
./build.sh -f tf/active_directory -a apply
```

- Configure the Domain Controler
```bash
./install.sh ad
```

- Build the remaining infrastructure VMs
```bash
./build.sh -a apply
```

- Create users passwords
```bash
./create_passwords.sh
```

- Install and configure all applications
```bash
./install.sh
```
## Deploy in a locked down network environment
A locked down network environemnt avoid access from public IPs to the resources used by az-hop like storage accounts and key vault for example. To enable such configuration, uncomment and fill out the `locked_down_network` settings. Use the `grant_access_from` to grant access to specific internet public IPs as documented from [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal#grant-access-from-an-internet-ip-range)

```yml
locked_down_network: 
  enforce: true
  grant_access_from: [a.b.c.d] # Array of CIDR to grant access from.
```

## Disable Public IP scenario
To deploy `az-hop` in a no public IP scenario you have to set the `locked_down_network:public_ip` value to `false`. The default value being `true`.

```yml
locked_down_network: 
  public_ip: false
```

In such scenario you need to use a `deployer` VM, make sure that this VM can access the `jumpbox` over SSH and the keyvault created. As there will be no public IP, the SSL Let's Encrypt certificate used for the OnDemand portal can't be generate, which means that you have to provide your own certificate.

> Note: One option is to provision that VM in the `admin` subnet and open an NSG rule for allowing SSH from that machine to the `jumbox`.

## Use your own SSL certificate
In a no public IP scenario, you will have to provide your own SSL certificate. If you want to generate your own self signed certificate here is how to proceed

```bash
openssl req -nodes -new -x509 -keyout certificate.key -out certificate.crt
```

Copy both files `certificate.key` and `certificate.crt` in the `./playbooks` directory and renamed them with the `ondemand_fqdn` variable value defined in the `./playbooks/group_vars/all.yml` file.

The playbook configuring OnDemand is expecting to find these files and will copy them in the ondemand VM when the no PIP option is set.

## Not deploy ANF
By default an Azure Netapp File account, pool and volume are created to host the users home directories, if you don't need to deploy such resources then comment or remove the `anf` section of the configuration file like this. In this case you will have to provide an NSF share for the users home directories see [Use an existing NFS mount point](#use-an-existing-nfs-mount-point)

```yml
# Define an ANF account, single pool and volume
# If not present assume that there is an existing NFS share for the users home directory
#anf:
  # Size of the ANF pool and unique volume
#  homefs_size_tb: 4
  # Service level of the ANF volume, can be: Standard, Premium, Ultra
#  homefs_service_level: Standard
  # dual protocol
#  dual_protocol: false # true to enable SMB support. false by default

```

## Use an existing NFS mount point
If you already have an existing NFS share, then it can be used for the users home directories, you can specify this one in the `mounts` section of the configuration file like below.

```yml
mounts:
  # mount settings for the user home directory
  home:
    mountpoint: <mount point name> # /sharedhome for example
    server: <server name or IP> # Specify an existing NFS server name or IP, when using the ANF built in use '{{anf_home_ip}}'
    export: <export directory> # Specify an existing NFS export directory, when using the ANF built in use '{{anf_home_path}}'
```

## Use Azure Active Directory for MFA
You can use AAD to enabled Multi Factor Authentication when using the az-hop portal. This is enabled thru OpenId Connect for which you need to provide the settings in the `config.yml` file.

```yml
# Authentication configuration for accessing the az-hop portal
# Default is basic authentication. For oidc authentication you have to specify the following values
# The OIDCClient secret need to be stored as a secret named <oidc-client-id>-password in the keyvault used by az-hop
authentication:
  httpd_auth: oidc # oidc or basic
  # User mapping https://osc.github.io/ood-documentation/latest/reference/files/ood-portal-yml.html#ood-portal-generator-user-map-match
  # Domain users are mapped to az-hop users with the same name and without the domain name
  user_map_match: '^([^@]+)@mydomain.foo$'
  ood_auth_openidc:
    OIDCProviderMetadataURL: # for AAD use 'https://sts.windows.net/{{tenant_id}}/.well-known/openid-configuration'
    OIDCClientID: 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
    OIDCRemoteUserClaim: # for AAD use 'upn'
    OIDCScope: # for AAD use 'openid profile email groups'
    OIDCPassIDTokenAs: # for AAD use 'serialized'
    OIDCPassRefreshToken: # for AAD use 'On'
    OIDCPassClaimsAs: # for AAD use 'environment'
  ```
The helper script `configure_aad.sh` can be used to 
- Register an AAD application configured to the az-hop environment
- Create a secret for this AAD application and store it in the az-hop Key Vault

This script need to be run before the `install.sh` or at least before the `ood` step.
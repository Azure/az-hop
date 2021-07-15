# How To

- [How to use an existing VNET ?](#how-to-use-an-existing-vnet)
  - [Pre-requisities for using an existing VNET](#pre-requisities-for-using-an-existing-vnet)

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
      compute:
        name: dynamic
```

### Pre-requisities for using an existing VNET
- There is a need of a minimum of 5 IP addresses for the infrastructure VMs
- Allow enough IP addresses for the Lustre cluster, default being 4 : Robinhood + Lustre + 2*OSS
- Delegate a subnet to Azure NetApp Files like documented [here](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-delegate-subnet)
- The *frontend* subnet needs to allow this traffic :
  - HTTPS/443 In => this is used by the OnDemand web portal and all end users
  - SSH/22 In => This is used when doing the deployment and by admins only


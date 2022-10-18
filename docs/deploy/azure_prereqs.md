# Azure Pre-requisites

- When using a user account 
  - you need to be **Owner** of the subscription
- When using a Service Principal Name, the service principal needs to be
  - **"Contributor"** on the subscription
  - **"User Access Administrator"** on the subscription
- When using a managed Identity on a deployer VM it needs to be a **System Managed Identity** with 
  - **"Contributor"** on the resource group
  - **"User Access Administrator"** on the subscription
  - **"Reader"** on the subscription
- Your subscription need to be registered for NetApp resource provider as explained [here](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-register#waitlist)
- If using ANF Dual Protocol be aware of the limitation of one ANF account allow to be domain joined per region in the same subscription
- The Azure HPC Lustre marketplace image terms need to be accepted
```bash
az vm image terms accept --offer azurehpc-lustre --publisher azhpc --plan azurehpc-lustre-2_12
```
- If AlmaLinux Marketplace image is used, the terms need to be accepted as well
```bash
az vm image terms accept --offer almalinux-hpc --publisher almalinux --plan 8_5-hpc-gen2
```

- When using the default configurations in order to build your environment, make sure you have enough quota for :
  - 10 cores of Standard BS Family
    - 5 x Standard_B2ms
  - 4 cores of Standard DSv5 Family
    - 1 x Standard_D4s_v5
  - 80 cores of Standard DDv4 Family
    - 2 x Standard_D8d_v4
    - 2 x Standard_D32d_v4
- For the compute and visualization nodes, you can adjust the maximum quota in your configuration file but make sure you have quota for these instances too :
  - For Code Server :
    - 10 cores of Standard FSv2 Family
  - For Compute Nodes depending on your configuration and needs :
    - 220 cores Standard_HC44rs
    - and/or 600 cores of Standard HBrsv2 Family
    - and/or 600 cores of Standard HBv3 Family
  - For Remote Visualization
    - 18 cores of Standard NV Family

## Special circumstances
- When deploying in a zero-trust environment that automatically blocks access to high-risk TCP/UDP ports (e.g. 22) from the internet, follow the [hub and spoke network architecture](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke?tabs=cli). 
  - In the hub, create:
    - the VPN gateway and virtual network
    - virtual machines for self-hosted Github Action runners
  - Each azhop deployment will be a spoke. 
    - See [define the deployment](https://azure.github.io/az-hop/deploy/define_environment.html) for how to automatically peer the virtual network of azhop with that of the hub, and for how to change the SSH port of the jumpbox.

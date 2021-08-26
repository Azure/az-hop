# Azure Pre-requisites

- When using a user account you need to be **Owner** of the subscription
- When using a Service Principal Name, it need to be **Contributor** and **User Access Administrator** on the subscription
- Your subscription need to be registered for NetApp resource provider as explained [here](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-register#waitlist)
- If using ANF Dual Protocol be aware of th limitation of one ANF account allow to be domain joined per region in the same subscription
- The CycleCloud marketplace image need to be allowed, this is the default unless your subscription have a policy blocking it. The EULA terms need to be accepted, this is done in the build script, but if you are not granted to do so, ask your adimnistrator to run this command :
```bash
az vm image terms accept --offer azure-cyclecloud --publisher azurecyclecloud --plan cyclecloud-81
```
- When using the default configurations in order to build your environment, make sure you have enough quota for :
  - 5 x Standard_D2s_v3 
  - 2 x Standard_D8d_v4 
  - 2 x Standard_D32d_v4
- For the compute and visualization nodes, you can adjust the maximum quota in your configuration file but make sure you have quota for these instances :
  - Standard_F2s_v2
  - Standard_HC44rs
  - Standard_HB60rs
  - Standard_HB120rs_v2
  - Standard_NV6

## Packer
Packer needs a Service Principal Name to deploy resources in your subscription
### Create a Service Principal Name

Run this command to generate a Service Principal Name. Keep the password value somewhere safe as it won't be shown again.
```bash
az ad sp create-for-rbac --name azhop-packer-spn
{
  "appId": "<some-generated-guid>",
  "displayName": "azhop-packer-spn",
  "name": "http://azhop-packer-spn",
  "password": "<generated-password>",
  "tenant": "<your-tenant-id>"
}
```

### Add the password in a keyvault secret

```bash
az keyvault secret set --value <generated-password> --name azhop-packer-spn --vault-name <your-keyvault>
```


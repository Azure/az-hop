# Azure Pre-requisites

> TODO :
> describe here all the azure pre-requisites
> which role the user deploying should have ?
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


# Deploying

Create parameter file, `mainTemplate.parameters.json`:

```
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "azhopResourceGroupName": {
      "value": ""
    },
    "adminUser": {
      "value": "hpcadmin"
    },
    "autogenerateSecrets": {
      "value": true
    },
    "softwareInstall": {
      "value": true
    }
  }
}
```

Perform a subscription deployment:

```
az deployment sub create --template-file mainTemplate.bicep --location westeurope --parameters @mainTemplate.parameters.json
```
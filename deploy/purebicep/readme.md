# Using bicep instead of Terraform
This is the scenario to provide compatibility with the existing mode of deploying using a local configuration file from either a local machine or an existing deployer VM.
- from a local machine "az login" with your user name.
- from a deployer VM "az login -i", the VM should have system assigned identity with the right roles as defined in the documentation.

```bash
./build.sh <path_to_config_file.yml>
```

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
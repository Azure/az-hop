#!/bin/bash

rg=paul-test-azhop-deploy-169
loc=westeurope
adminName=deploy

if [[ ! -f "$adminName" ]]; then
    ssh-keygen -f $adminName  -N ''
fi

az group create --resource-group $rg --location $loc

az deployment group create \
    --resource-group $rg \
    --template-file main.bicep \
    --parameters deployUsername=$adminName deployKey="$(<${adminName}.pub)"

# Add these in bicep
# service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Sql"]

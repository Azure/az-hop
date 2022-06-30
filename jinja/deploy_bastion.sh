#!/bin/bash

rg=$1
pass=$2

if [ "$rg" == "" ]; then
    echo "Usage: $0 <resource group>"
    exit 1
fi

az group create --location westeurope --name $rg
az deployment group create \
    --resource-group $rg \
    --template-file ubuntuBastionRdp.bicep \
    --parameters \
        adminUser=hpcadmin \
        adminPassword="$pass"

#!/bin/bash

rg=$1

if [ "$rg" == "" ]; then
    echo "Usage: $0 <resource group>"
    exit 1
fi

winpassword=$(pwgen -s 12 -1)
slurmactpassword=$(pwgen -s 12 -1)

./generate.py > azhop.bicep
az group create --location westeurope --name $rg
az deployment group create \
    --resource-group $rg \
    --template-file azhop.bicep \
    --parameters \
        adminUser=hpcadmin \
        adminPassword="$winpassword" \
        adminSshKey="$(<~/.ssh/id_rsa.pub)" \
        slurmAccountingAdminUser=sqladmin \
        slurmAccountingAdminPassword="$slurmactpassword"

#!/bin/bash

rg=azhoprg
loc=westeurope
adminName=deploy

if [[ ! -f "$adminName" ]]; then
    ssh-keygen -f $adminName -N ''
fi

az group create --resource-group $rg --location $loc

az deployment group create \
    --resource-group $rg \
    --template-file main.bicep \
    --parameters jumpboxUsername=$adminName jumpboxKey="$(<${adminName}.pub)"

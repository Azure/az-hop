#!/bin/bash

rg=$1

if [ "$rg" == "" ]; then
    echo "Usage: $0 <resource group>"
    exit 1
fi

adminuser=$(yq .admin_user config.yml)
winpassword=$(pwgen -s 12 -1)
slurmadmin=$(yq .slurm.admin_user config.yml)
slurmactpassword=$(pwgen -s 12 -1)

if [[ ! -f "${adminuser}_id_rsa" ]]; then
    ssh-keygen -f "${adminuser}_id_rsa"  -N ''
fi

./generate.py > azhop.bicep
az group create --location westeurope --name $rg
az deployment group create \
    --resource-group $rg \
    --template-file azhop.bicep \
    --parameters \
        adminUser=$adminuser \
        adminPassword="$winpassword" \
        adminSshKey="$(<${adminuser}_id_rsa.pub)" \
        slurmAccountingAdminUser=$slurmadmin \
        slurmAccountingAdminPassword="$slurmactpassword" \
    2>&1 | tee deploy.log

jq '.properties.outputs | to_entries | map({(.key): .value.value}) | add' <deploy.log | yq -P | tee outputs.yml

./generate_template_file.py

cp templates/config.yml ../config.yml
mkdir -p ../bin
cp templates/get_secret ../bin
chmod +x ../bin/get_secret
cp templates/connect ../bin
chmod +x ../bin/connect
mkdir -p ../playbooks/group_vars
cp templates/global_variables ../playbooks/group_vars/all.yml
cp templates/inventory ../playbooks
cp ${adminuser}_id_rsa* ..

subscription_id=$(yq .subscription_id outputs.yml)

echo "Command to create tunnel:"
echo "az network bastion tunnel --port 8022 --resource-port 22 --name bastion --resource-group $rg --target-resource-id /subscriptions/$subscription_id/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/jumpbox"
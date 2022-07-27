#!/bin/bash
set -e
set -o pipefail
rg=$1
location=${2:-westeurope}

if [ "$rg" == "" ]; then
    echo "Usage: $0 <resource group> <location>"
    exit 1
fi

adminuser=hpcadmin
winpassword=$(pwgen -s 12 -1)
slurmadmin=sqladmin
slurmactpassword=$(pwgen -s 12 -1)

if [[ ! -f "${adminuser}_id_rsa" ]]; then
    ssh-keygen -f "${adminuser}_id_rsa"  -N ''
fi

slurmAdminUserArg=
slurmAdminPasswordArg=

if [[ $(yq .queue_manager build.yml) == "slurm" && $(yq .slurm.accounting_enabled build.yml) == "true" ]]; then
    slurmAdminUserArg="slurmAccountingAdminUser=$slurmadmin"
    slurmAdminPasswordArg="slurmAccountingAdminPassword=$slurmactpassword"
fi

./build.sh
az group create --location $location --name $rg
az deployment group create \
    --resource-group $rg \
    --template-file azureDeploy.bicep \
    --parameters \
        adminUser=$adminuser \
        adminPassword="$winpassword" \
        adminSshPublicKey="$(<${adminuser}_id_rsa.pub)" \
        adminSshPrivateKey="$(<${adminuser}_id_rsa)" \
        $slurmAdminUserArg $slurmAdminPasswordArg \
    | tee deploy.log

jq '.properties.outputs | to_entries | map({(.key): .value.value}) | add' <deploy.log | yq -P | tee outputs.yml

subscription_id=$(yq .subscription_id <outputs.yml)

echo
echo "Command to create tunnel:"
echo "az network bastion tunnel --port 8022 --resource-port 22 --name bastion --resource-group $rg --target-resource-id /subscriptions/$subscription_id/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/jumpbox"

echo "Command to ssh to deployer"
echo "az network bastion ssh --name bastion --resource-group $rg --target-resource-id /subscriptions/$subscription_id/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/deployer --username $adminuser --ssh-key ${adminuser}_id_rsa --auth-type ssh-key"
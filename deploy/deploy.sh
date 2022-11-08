#!/bin/bash
set -e
set -o pipefail
rg=$1
location=${2:-westeurope}
branch=${3:-main}

parameter_file=$rg-$location.params.json

if [ "$rg" == "" ]; then
    echo "Usage: $0 <resource group> <location>"
    exit 1
fi

# Retrieve the user principal ID to grant access to the KV

user_type=$(az account show --query user.type -o tsv)
if [ ${user_type} == "user" ]; then
  logged_user_objectId=$(az ad signed-in-user show --query id -o tsv)
else
  export clientId=$(az account show --query user.name -o tsv)
  case "${clientId}" in
      "systemAssignedIdentity")
          mds=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-08-15")
          vmname=$(echo $mds | jq -r '.compute.name')
          rgname=$(echo $mds | jq -r '.compute.resourceGroupName')
          echo " - logged in Azure with System Assigned Identity from ${vmname}/${rgname}"
          logged_user_objectId=$(az resource list -n $vmname -g $rgname --query [*].identity.principalId --out tsv)
          if [ "$logged_user_objectId" == "" ]; then
            logged_user_objectId=$(az resource list -n $vmname -g $rgname --query [*].identity.userAssignedIdentities.*.principalId --out tsv)
          fi
          ;;
      "userAssignedIdentity")
          echo "userAssignedIdentity not supported; please use a systemAssignedIdentity or a Service Principal Name instead"
          exit 1
          ;;
      *)
          logged_user_objectId=$(az ad sp show --id ${clientId} --query id -o tsv)
          ;;
  esac
fi

sed -i "s/^keyvault_readers: \[/keyvault_readers: \[$logged_user_objectId,/g" build.yml

# When applied on an existing deployment, don't create new passwords
adminuser=hpcadmin
slurmadmin=sqladmin
slurmactpassword=""

if [[ ! -f "${adminuser}_id_rsa" ]]; then
    ssh-keygen -f "${adminuser}_id_rsa"  -N ''
fi

slurmAdminUserArg=
slurmAdminPasswordArg=

if [ ! -e $parameter_file ]; then
echo "Parameter file doesn't exists, create it"
winpassword=$(openssl rand -base64 24)
if [[ $(yq .queue_manager build.yml) == "slurm" && $(yq .slurm.accounting_enabled build.yml) == "true" ]]; then
slurmactpassword=$(openssl rand -base64 24)
fi

cat <<EOF >$parameter_file
{
    "\$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "adminUser": {
            "value": "$adminuser"
        },
        "homedirMountpoint": {
            "value": "/anfhome"
        },
        "adminSshPublicKey": {
            "value": "$(<${adminuser}_id_rsa.pub)"
        },
        "adminSshPrivateKey": {
            "value": "$(<${adminuser}_id_rsa)"
        },
        "adminPassword": {
            "value": "$winpassword"
        },
        "location": {
            "value": "$location"
        },
        "slurmAccountingAdminUser": {
            "value": "$slurmadmin"
        },
        "slurmAccountingAdminPassword": {
            "value": "$slurmactpassword"
        },
        "branchName": {
            "value": "$branch"
        }
    }
}
EOF
fi

./build.sh

az group create --location $location --name $rg
az deployment group create \
    --resource-group $rg \
    --template-file azureDeploy.bicep \
    --parameters @$parameter_file \
    | tee deploy.log

jq '.properties.outputs | to_entries | map({(.key): .value.value}) | add' <deploy.log | yq -P | tee outputs.yml

subscription_id=$(yq .subscription_id <outputs.yml)

# Grant subscription reader for the ccportal-mi
managedId=$(az identity show -n ccportal-mi -g $rg --query 'principalId' -o tsv)
az role assignment create --assignee "$managedId" --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" --subscription "$subscription_id" -o tsv | tee deploy.log

echo
echo "Command to create tunnel:"
echo "az network bastion tunnel --port 8022 --resource-port 22 --name bastion --resource-group $rg --target-resource-id /subscriptions/$subscription_id/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/deployer"

echo "Command to ssh to deployer"
echo "az network bastion ssh --name bastion --resource-group $rg --target-resource-id /subscriptions/$subscription_id/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/deployer --username $adminuser --ssh-key ${adminuser}_id_rsa --auth-type ssh-key"

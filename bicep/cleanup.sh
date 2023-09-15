#!/bin/bash
set +e
AZHOP_CONFIG=config.yml
ANSIBLE_VARIABLES=playbooks/group_vars/all.yml

if [ ! -e $AZHOP_CONFIG ]; then
  echo "$AZHOP_CONFIG doesn't exist, exiting"
  exit 1
fi

rg=$(yq '.resource_group' $AZHOP_CONFIG)

# Delete and Purge keyvault
key_vault=$(yq eval '.key_vault' $ANSIBLE_VARIABLES)
if [ "$key_vault" != "" ]; then
    echo "Delete keyvault $key_vault"
    az keyvault delete --name $key_vault
    echo "Purging keyvault $key_vault"
    az keyvault purge --name $key_vault
fi

# Remove role assignments for ccportal at the subscription level
cc_portalname=$(yq eval '.cyclecloud.name' $AZHOP_CONFIG)
if [ "$cc_portalname" == "" ]; then
  cc_portalname="ccportal"
fi
ccportal_id=$(az vm show -n $cc_portalname -g $rg --query 'identity.principalId' -o tsv)
if [ "$ccportal_id" != "" ]; then
  echo "Removing role assignments for ccportal"
  az role assignment delete --assignee $ccportal_id
fi

# Remove Role assignments for ccportal at the resource group level
az role assignment list --assignee $ccportal_id -g $rg --query "[].{name:roleDefinitionName, scope:scope}" -o tsv | while read name scope; do
  echo "Removing role assignment $name for ccportal"
  az role assignment delete --assignee $ccportal_id --role $name --scope $scope
done

# removing first peer => need to work to do all !!!!
peered_vnet=$(yq ".network.peering[0].vnet_name" $AZHOP_CONFIG)
if [ "$peered_vnet" != "null" ]; then
    peered_vnet_rg=$(yq ".network.peering[0].vnet_resource_group" $AZHOP_CONFIG)
    if [ "$peered_vnet_rg" != "null" ]; then
      id=$(az network vnet peering list -g $peered_vnet_rg --vnet-name $peered_vnet --query "[?remoteVirtualNetwork.resourceGroup=='$rg'].id" -o tsv)
      if [ "$id" != "" ]; then
        echo "Deleting peering $id"
        az network vnet peering delete --ids $id
      fi
    fi
fi
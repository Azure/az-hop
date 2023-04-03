#!/bin/bash
# Try to sync Terraform State after resources being created or updated outside of TF
set -e
set -o pipefail
AZHOP_CONFIG=config.yml
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TF_FOLDER=$THIS_DIR/tf

if [ -d ${THIS_DIR}/miniconda ]; then
  echo "Activating conda environment"
  source ${THIS_DIR}/miniconda/bin/activate
fi

terraform -chdir=tf show -json plan.tfplan | jq '.' > tf/plan.json
jq '.planned_values.root_module.resources[] | select(.address) | .address' tf/plan.json 

resource_group=$(yq eval '.resource_group' $AZHOP_CONFIG)
subscription_id=$(az account show -o json | jq -r '.id')

# Retrieve the unique suffix from the keyvault name
kv_name=$(az keyvault list -g $resource_group --query "[].name" -o tsv)
if [ -z $kv_name ]; then
    echo "Keyvault $kv_name not found in $resource_group"
    exit 1
fi
suffix=${kv_name:2:${#kv_name}}
echo $suffix

function get_resource_id () {
    local resource_type=$1
    local resource_name=$2

    az resource list --resource-type $resource_type --subscription $subscription_id --resource-group $resource_group -o json --query "[?name=='$resource_name']" | jq -r '.[0].id'
}


function import_state () {
    local tf_name=$1
    local resource_type=$2
    local resource_name=$3

    # Check if the resource is already imported
    set +e
    result=$(terraform -chdir=$TF_FOLDER state list | grep -F $tf_name)
    set -e
    if [ "$result" != "" ]; then
        echo "Resource $tf_name already imported"
    else
        if [ "$resource_type" == "resourceGroups" ]; then
            resource_id="/subscriptions/$subscription_id/resourceGroups/$resource_group"
        else
            resource_id=$(get_resource_id $resource_type $resource_name $resource_group $subscription_id)
        fi
        if [ "$resource_id" == "null" ]; then
            echo "Resource $resource_name not found"
            exit 1
        fi

        echo "Importing $tf_name from $resource_id"
        terraform -chdir=$TF_FOLDER import $tf_name $resource_id
    fi
}

# Import Resource Group
import_state azurerm_resource_group.rg[0] resourceGroups $resource_group

# Import virtual machines
import_state azurerm_linux_virtual_machine.ad Microsoft.Compute/virtualMachines ad
import_state azurerm_network_interface.ad-nic Microsoft.Network/networkInterfaces ad-nic

import_state azurerm_linux_virtual_machine.jumpbox[0] Microsoft.Compute/virtualMachines jumpbox
import_state azurerm_network_interface.jumpbox-nic[0] Microsoft.Network/networkInterfaces jumpbox-nic

import_state azurerm_linux_virtual_machine.ccportal Microsoft.Compute/virtualMachines ccportal
import_state azurerm_network_interface.ccportal-nic Microsoft.Network/networkInterfaces ccportal-nic
import_state azurerm_managed_disk.ccportal_datadisk Microsoft.Compute/disks ccportal-datadisk0

import_state azurerm_linux_virtual_machine.ondemand Microsoft.Compute/virtualMachines ondemand
import_state azurerm_network_interface.ondemand-nic Microsoft.Network/networkInterfaces ondemand-nic

import_state azurerm_linux_virtual_machine.scheduler Microsoft.Compute/virtualMachines scheduler
import_state azurerm_network_interface.scheduler-nic Microsoft.Network/networkInterfaces scheduler-nic

import_state azurerm_linux_virtual_machine.grafana Microsoft.Compute/virtualMachines grafana
import_state azurerm_network_interface.grafana-nic Microsoft.Network/networkInterfaces grafana-nic

# Import Network
import_state azurerm_virtual_network.azhop[0] Microsoft.Network/virtualNetworks hpcvnet

# Import Key Vault
import_state azurerm_key_vault.azhop Microsoft.KeyVault/vaults kv$suffix

# Import Storage Account
import_state azurerm_storage_account.azhop Microsoft.Storage/storageAccounts azhop$suffix

# Import Image Gallerie
import_state azurerm_shared_image_gallery.sig Microsoft.Compute/galleries azhop_$suffix

# Import ANF
import_state azurerm_netapp_account.azhop[0] Microsoft.NetApp/netAppAccounts azhop-$suffix
import_state azurerm_netapp_pool.anfpool[0] Microsoft.NetApp/netAppAccounts/capacityPools azhop-$suffix/anfpool-$suffix
import_state azurerm_netapp_volume.home[0] Microsoft.NetApp/netAppAccounts/capacityPools/volumes azhop-$suffix/anfpool-$suffix/anfhome
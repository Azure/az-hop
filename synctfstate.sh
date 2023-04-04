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
    #exit 1
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
        else
            echo "Importing $tf_name from $resource_id"
            terraform -chdir=$TF_FOLDER import $tf_name $resource_id
        fi
    fi
}

# Import Resource Group
import_state azurerm_resource_group.rg[0] resourceGroups $resource_group

# Import Network
import_state azurerm_virtual_network.azhop[0] Microsoft.Network/virtualNetworks hpcvnet
import_state azurerm_application_security_group.asg[\"asg-ssh\"] Microsoft.Network/applicationSecurityGroups asg-ssh
import_state azurerm_application_security_group.asg[\"asg-rdp\"] Microsoft.Network/applicationSecurityGroups asg-rdp
import_state azurerm_application_security_group.asg[\"asg-jumpbox\"] Microsoft.Network/applicationSecurityGroups asg-jumpbox
import_state azurerm_application_security_group.asg[\"asg-ad\"] Microsoft.Network/applicationSecurityGroups asg-ad
import_state azurerm_application_security_group.asg[\"asg-ad-client\"] Microsoft.Network/applicationSecurityGroups asg-ad-client
import_state azurerm_application_security_group.asg[\"asg-lustre\"] Microsoft.Network/applicationSecurityGroups asg-lustre
import_state azurerm_application_security_group.asg[\"asg-lustre-client\"] Microsoft.Network/applicationSecurityGroups asg-lustre-client
import_state azurerm_application_security_group.asg[\"asg-pbs\"] Microsoft.Network/applicationSecurityGroups asg-pbs
import_state azurerm_application_security_group.asg[\"asg-pbs-client\"] Microsoft.Network/applicationSecurityGroups asg-pbs-client
import_state azurerm_application_security_group.asg[\"asg-cyclecloud\"] Microsoft.Network/applicationSecurityGroups asg-cyclecloud
import_state azurerm_application_security_group.asg[\"asg-cyclecloud-client\"] Microsoft.Network/applicationSecurityGroups asg-cyclecloud-client
import_state azurerm_application_security_group.asg[\"asg-nfs-client\"] Microsoft.Network/applicationSecurityGroups asg-nfs-client
import_state azurerm_application_security_group.asg[\"asg-telegraf\"] Microsoft.Network/applicationSecurityGroups asg-telegraf
import_state azurerm_application_security_group.asg[\"asg-grafana\"] Microsoft.Network/applicationSecurityGroups asg-grafana
import_state azurerm_application_security_group.asg[\"asg-robinhood\"] Microsoft.Network/applicationSecurityGroups asg-robinhood
import_state azurerm_application_security_group.asg[\"asg-ondemand\"] Microsoft.Network/applicationSecurityGroups asg-ondemand
import_state azurerm_application_security_group.asg[\"asg-deployer\"] Microsoft.Network/applicationSecurityGroups asg-deployer
import_state azurerm_application_security_group.asg[\"asg-guacamole\"] Microsoft.Network/applicationSecurityGroups asg-guacamole
import_state azurerm_application_security_group.asg[\"asg-mariadb-client\"] Microsoft.Network/applicationSecurityGroups asg-mariadb-client

# Import virtual machines
import_state azurerm_windows_virtual_machine.ad[0] Microsoft.Compute/virtualMachines ad
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
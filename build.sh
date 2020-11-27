#!/bin/bash
set -e
TFVARS_FILE=${1:-terraform.tfvars}

function get_resource_group {
  RESOURCE_GROUP=$(grep "resource_group=" $TFVARS_FILE | cut -d'=' -f2)
  
  if [ "$RESOURCE_GROUP" == "<NOT-SET>" ]; then
    echo "Please fill up the 'resource_group' value in $TFVARS_FILE"
    exit 1
  fi

  # if [ ! -e $RG_FILE ]; then
  #   UUID="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
  #   RESOURCE_GROUP="hpc_$UUID"
  #   echo $RESOURCE_GROUP > $RG_FILE
  # else
  #   RESOURCE_GROUP=$(cat $RG_FILE)
  # fi

}

function get_storage_id {
  # get the storage account ID to use
  id=$(az storage account list -g $RESOURCE_GROUP --query "[?contains(@.name, 'storage')==\`true\`].id" | jq -r '.[0]')
  if [ ${id} == null ]; then
    echo "no storage account found to store the TF state"
    exit 1
  fi
}

get_resource_group

terraform init ./tf
#terraform apply -auto-approve -parallelism=30 -var location=westeurope -var resource_group=$RESOURCE_GROUP ./tf




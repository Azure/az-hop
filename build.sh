#!/bin/bash
set -e
TFVARS_FILE=${1:-terraform.tfvars}
TF_COMMAND=${2:-plan}
TF_BACKEND_FILE=./tf/backend.tf

function get_resource_group {
  RESOURCE_GROUP=$(grep "resource_group" $TFVARS_FILE | cut -d'=' -f2 | xargs)
  
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

# Set the ARM_ACCESS_KEY env variable to be used by TF to manage states in azure blobs backend
# The ./tf/backend.tf file contains the values of the storage ressource group, account and container to be used
function get_arm_access_key {

  if [ ! -e $TF_BACKEND_FILE ]; then
    echo "No backend specified, using local state"
  else
    RESOURCE_GROUP_NAME=$(grep "resource_group_name" $TF_BACKEND_FILE | cut -d'=' -f 2 | xargs)
    STORAGE_ACCOUNT_NAME=$(grep "storage_account_name" $TF_BACKEND_FILE | cut -d'=' -f 2 | xargs)
    ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

    if [ "$ACCOUNT_KEY" == "" ]; then
      echo "unable to retrieve the account key for accessing terraform blob backend"
      exit 1
    fi

    echo "Using backend stored in $RESOURCE_GROUP_NAME/$STORAGE_ACCOUNT_NAME"
    export ARM_ACCESS_KEY=$ACCOUNT_KEY
  fi
}


#get_resource_group
get_arm_access_key

terraform init ./tf
terraform $TF_COMMAND -parallelism=30 -var-file=$TFVARS_FILE ./tf
#terraform apply -parallelism=30 -var-file=$TFVARS_FILE ./tf
#terraform apply -auto-approve -parallelism=30 -var location=westeurope -var resource_group=$RESOURCE_GROUP ./tf




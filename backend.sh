#!/bin/bash
LOCATION=${1:-westeurope}
RESOURCE_GROUP_NAME=tfstate-$LOCATION
CONTAINER_NAME=tfstate
TFSTATE_FILE=deploy$RANDOM

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION -o table

STORAGE_ACCOUNT_NAME=$(az storage account list -g $RESOURCE_GROUP_NAME --query "[?contains(@.name, 'tfstate')==\`true\`].name" | jq -r '.[0]')
if [ ${STORAGE_ACCOUNT_NAME} == null ]; then
  STORAGE_ACCOUNT_NAME=tfstate$RANDOM
  # Create storage account
  az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob -o table
fi

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY -o table

echo "storage_account_name: $STORAGE_ACCOUNT_NAME"
echo "container_name: $CONTAINER_NAME"
echo "access_key: $ACCOUNT_KEY"
echo "TF State:" $TFSTATE_FILE

cat <<EOF >./tf/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name   = "$RESOURCE_GROUP_NAME"
    storage_account_name  = "$STORAGE_ACCOUNT_NAME"
    container_name        = "$CONTAINER_NAME"
    key                   = "$TFSTATE_FILE"
  }
}
EOF

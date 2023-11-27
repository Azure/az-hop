#!/bin/bash
set -e
RESOURCE_GROUP=$1
VM_NAME=$2

function usage()
{
  echo "Usage : enable_aadssh.sh <resource_group> <vm_name>"
  echo "   "
}

# Check that resource groups is set
if [ -z "$RESOURCE_GROUP" ]; then
  echo "Resource Group is required"
  usage
  exit 1
fi

# Check that VM_NAME Name is set
if [ -z "$VM_NAME" ]; then
  echo "VM Name is required"
  usage
  exit 1
fi


# Set the AAD SSH Login for Linux extension
az vm extension set \
    --publisher Microsoft.Azure.ActiveDirectory \
    --name AADSSHLoginForLinux \
    --resource-group $RESOURCE_GROUP \
    --vm-name $VM_NAME

username=$(az account show --query user.name --output tsv)
rg=$(az group show --resource-group $RESOURCE_GROUP --query id -o tsv)

az role assignment create \
    --role "Virtual Machine Administrator Login" \
    --assignee $username \
    --scope $rg

yellow=$'\e[1;33m'
default=$'\e[0m'

printf "To connect to the $VM_NAME VM, use the following command:"
printf "\n${yellow}az ssh vm -n $VM_NAME -g $RESOURCE_GROUP --port 8822${default}\n"
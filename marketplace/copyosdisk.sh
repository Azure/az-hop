#!/bin/bash
set -e
set -o pipefail

osdisk_name=$1
osdisk_resource_group=$2

echo "Retrieving the os_disk_id for disk name $osdisk_name"
os_disk_id=$(az disk list -g azhop_build_images --query "[?name=='$osdisk_name'].id" -o tsv)

echo "Retrieving the image version for os disk"
image_version=$(az disk show --id $os_disk_id --query "tags.Version" -o tsv)
echo "Image version is $image_version"
echo "Create the disk SAS"
osdisk_sas=$(az disk grant-access --access-level Read --duration-in-seconds 3600 --name $osdisk_name --resource-group $osdisk_resource_group | jq .accessSas -r)

SA_ACCOUNT=azhop
SA_CONTAINER=images

image_name=$osdisk_name-v$image_version.vhd

start=$(date -u -d "-10 minutes" '+%Y-%m-%dT%H:%MZ')
expiry=$(date -u -d "+1 hour" '+%Y-%m-%dT%H:%MZ')

rw_sas=$(az storage container generate-sas --account-name $SA_ACCOUNT --name $SA_CONTAINER --permissions rwdl --start $start --expiry $expiry --output tsv)

azcopy copy --overwrite "ifSourceNewer" "$osdisk_sas" "https://$SA_ACCOUNT.blob.core.windows.net/$SA_CONTAINER/$image_name?${rw_sas}"

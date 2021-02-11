#!/bin/bash
# Download / Upload state files from blobs
# Skip any existing newer local ones
COMMAND=${1,,}
SA_ACCOUNT=$2
SA_CONTAINER=$3

STATE_DIR=.state

function usage()
{
  echo "azhop_state command account container"
  echo "    command   = download or upload"
  echo "    account   = azure storage account to read/write state"
  echo "    container = container to use"
  exit 1
}

if [ "$COMMAND" != "upload" ] && [ "$COMMAND" != "download" ]; then
  usage
fi

AZHOP_CONFIG=config.yml

if [ ! -e $AZHOP_CONFIG ]; then
  echo "$AZHOP_CONFIG doesn't exist, exiting"
  exit
fi

RESOURCE_GROUP=$(yq eval '.resource_group' $AZHOP_CONFIG)
if [ -z $RESOURCE_GROUP ]; then
  echo "Resource group is empty, exiting"
  exit
fi

start=$(date -u -d "-10 minutes" '+%Y-%m-%dT%H:%MZ')
expiry=$(date -u -d "60 minutes" '+%Y-%m-%dT%H:%MZ')

case $COMMAND in 
  download)
    sas=$(az storage container generate-sas --account-name $SA_ACCOUNT --name $SA_CONTAINER --permissions rl --start $start --expiry $expiry --output tsv)
    azcopy copy "https://$SA_ACCOUNT.blob.core.windows.net/$SA_CONTAINER/$RESOURCE_GROUP/*?$sas" "$STATE_DIR" --recursive --overwrite=ifSourceNewer

    # Use a local state directory as azcopy swallow the prefix file name if this one is the same that the directory name !!! 
    # This will also help uploading the whole directory content as well
    cp -r -u $STATE_DIR/* .
    # Fix SSH Keys permission as they are not preserved
    ADMIN_USER=$(yq eval '.admin_user' $AZHOP_CONFIG)
    chmod 600 ${ADMIN_USER}_id_rsa
    chmod 644 ${ADMIN_USER}_id_rsa.pub
    # Add chmod+x on scripts
    chmod +x /bin/*.sh
  ;;

  upload)
    # Copy state files into the state directory
    mkdir -p $STATE_DIR
    cp $AZHOP_CONFIG $STATE_DIR
    ADMIN_USER=$(yq eval '.admin_user' $AZHOP_CONFIG)
    cp ${ADMIN_USER}_id_rsa $STATE_DIR
    cp ${ADMIN_USER}_id_rsa.pub $STATE_DIR
    mkdir -p $STATE_DIR/packer
    cp packer/options.json $STATE_DIR/packer/options.json
    mkdir -p $STATE_DIR/playbooks/group_vars
    cp playbooks/group_vars/all.yml $STATE_DIR/playbooks/group_vars
    cp playbooks/inventory $STATE_DIR/playbooks
    mkdir -p $STATE_DIR/tf
    cp tf/terraform.tfstate $STATE_DIR/tf
    mkdir -p $STATE_DIR/bin
    cp bin/* $STATE_DIR/bin

    sas=$(az storage container generate-sas --account-name $SA_ACCOUNT --name $SA_CONTAINER --permissions rwdl --start $start --expiry $expiry --output tsv)
    azcopy copy "$STATE_DIR/*" "https://$SA_ACCOUNT.blob.core.windows.net/$SA_CONTAINER/$RESOURCE_GROUP?$sas"  --recursive --overwrite=ifSourceNewer
  ;;
esac


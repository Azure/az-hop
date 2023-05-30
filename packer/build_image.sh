#!/bin/bash
# Build an image with packer and the provided packer file
# There are 2 options for providing the SPN used by packer
#  - With environment variables like in github actions
#     * ARM_CLIENT_ID, ARM_CLIENT_SECRET and ARM_TENANT_ID
#  - Thru the spn.json config file
set -e
set -o pipefail
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OPTIONS_FILE=options.json
FORCE=0
SPN_FILE=spn.json
CONFIG_FILE=../config.yml
ANSIBLE_VARIABLES=../playbooks/group_vars/all.yml

if [ $# -lt 2 ]; then
  echo "Usage build_image.sh "
  echo "  Required arguments:"
  echo "    -i|--image <image_file.json> | image packer file"
  echo "   "
  echo "  Optional arguments:"
  echo "    -o|--options <options.json>  | file with options for packer generated in the build phase"
  echo "    -f|--force                   | overwrite existing image and always push a new version in the SIG"
  echo "    -k|--keep                    | keep os disk for future reused"
  exit 1
fi

load_miniconda() {
  # Note: packaging this inside a function to avoid forwarding arguments to conda
  if [ -d ${THIS_DIR}/../miniconda ]; then
    echo "Activating conda environment"
    source ${THIS_DIR}/../miniconda/bin/activate
  fi
}

load_miniconda
# Check config syntax
yamllint $CONFIG_FILE

PACKER_OPTIONS="-timestamp-ui"
KEEP_OS_DISK="false"

while (( "$#" )); do
  case "${1}" in
    -i|--image)
      PACKER_FILE=${2}
      shift 2
    ;;
    -o|--options)
      OPTIONS_FILE=${2}
      shift 2
    ;;
    -f|--force)
      FORCE=1
      PACKER_OPTIONS+=" -force"
      shift 1
    ;;
    -k|--keep)
      KEEP_OS_DISK="true"
      shift 1
    ;;
    *)
      shift
      ;;
  esac
done

if [ ! -f ${PACKER_FILE} ]; then
  echo "Packer file ${PACKER_FILE} not found"
  exit 1
fi

tenant_id=$(az account show -o json | jq -r .tenantId)
user_type=$(az account show --query user.type -o tsv)
if [ ${user_type} == "user" ]; then
  use_azure_cli_auth=true
else
  export clientId=$(az account show --query user.name -o tsv)
  case "${clientId}" in
      "systemAssignedIdentity")
          vmname=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-08-15" | jq -r '.compute.name')
          echo " - logged in Azure with System Assigned Identity from ${vmname}"
          use_azure_cli_auth=false
          ;;
      "userAssignedIdentity")
          echo "userAssignedIdentity not supported; please use a systemAssignedIdentity or a Service Principal Name instead"
          exit 1
          ;;
      *)
          use_azure_cli_auth=true
          logged_user_upn=$(az ad sp show --id ${clientId} --query displayName -o tsv)
          echo " - logged in Azure with Service Principal Name ${logged_user_upn}"
          ;;
  esac
fi

image_name=$(basename "$PACKER_FILE")
image_name="${image_name%.*}"

# Retrieve the Image ID
resource_group=$(jq -r '.var_resource_group' $OPTIONS_FILE)
image_id=$(az image list -g $resource_group --query "[?name=='$image_name'].id" -o tsv)

# Generate install script checksum
set +e
find ./scripts/ -exec md5sum {} \; > md5sum.txt
md5sum $PACKER_FILE >> md5sum.txt
set -e
packer_md5=$(md5sum md5sum.txt | cut -d' ' -f 1)
echo "scripts checksum is $packer_md5"

# if the image exists compare the build scripts checksum
if [ "$image_id" != "" ]; then
  image_checksum=$(az image show --id $image_id --query "tags.checksum" -o tsv)
  echo "Image checksum is $image_checksum"
  if [ "$packer_md5" != "$image_checksum" ]; then
    FORCE=1
    PACKER_OPTIONS+=" -force"
  fi
fi

# Build a new image if :
#   - Image doesn't exists
#   - Scripts to build the image have changed
#   - The force option is used
if [ "$image_id" == "" ] || [ $FORCE -eq 1 ]; then
  logfile="${PACKER_FILE%.*}.log"

  # Retrieve on which cloud environment we run on
  cloud_env="Public"
  account_env=$(az account show | jq '.environmentName' -r)
  case "$account_env" in
    AzureUSGovernment)
      cloud_env="USGovernment"
      ;;
    AzureCloud)
      cloud_env="Public"
      ;;
    *)
      cloud_env="Public"
      ;;
  esac

  echo "Build or Rebuid $image_name in $resource_group (writing log to $logfile)"
  key_vault_name=$(yq eval ".key_vault" $ANSIBLE_VARIABLES)

  echo "Removing os disk if any"
  os_disk_id=$(az disk list -g $resource_group --query "[?name=='$image_name'].id" -o tsv)
  if [ "$os_disk_id" != "" ]; then
    az disk delete --ids $os_disk_id -o tsv -y
  fi

  packer build $PACKER_OPTIONS -var-file $OPTIONS_FILE \
    -var "var_use_azure_cli_auth=$use_azure_cli_auth" \
    -var "var_image=$image_name" \
    -var "var_img_version=$version" \
    -var "var_cloud_env=$cloud_env" \
    -var "var_key_vault_name=$key_vault_name" \
    -var "var_keep_os_disk=$KEEP_OS_DISK" \
    $PACKER_FILE | tee $logfile

  image_id=$(az image list -g $resource_group --query "[?name=='$image_name'].id" -o tsv)
  # Tag the image with the checksum 
  echo "Tagging the source image with checksum $packer_md5"
  az image update --ids $image_id --tags checksum=$packer_md5 -o tsv

else
  echo "Image $image_name exists, skipping building the image"
fi

sig_name=$(jq -r '.var_sig_name' $OPTIONS_FILE)

# Create the image definition if it doesn't exists
img_def_id=$(az sig image-definition list -r $sig_name -g $resource_group --query "[?name=='$image_name'].id" -o tsv)
if [ "$img_def_id" == "" ]; then
  echo "Creating an image definition for $image_name"
  # Get the image definition from the config file
  echo "Read image definition from $CONFIG_FILE"
  eval_str=".images[] | select(.name == "\"$image_name"\") | .offer"
  offer=$(yq eval "$eval_str" $CONFIG_FILE)
  eval_str=".images[] | select(.name == "\"$image_name"\") | .publisher"
  publisher=$(yq eval "$eval_str" $CONFIG_FILE)
  eval_str=".images[] | select(.name == "\"$image_name"\") | .sku"
  sku=$(yq eval "$eval_str" $CONFIG_FILE)
  eval_str=".images[] | select(.name == "\"$image_name"\") | .hyper_v"
  hyper_v=$(yq eval "$eval_str" $CONFIG_FILE)
  if [ "$hyper_v" == "" ]; then 
    hyper_v="V1"
  fi
  eval_str=".images[] | select(.name == "\"$image_name"\") | .os_type"
  os_type=$(yq eval "$eval_str" $CONFIG_FILE)

  az sig image-definition create -r $sig_name -i $image_name -g $resource_group \
                -f $offer --os-type $os_type -p $publisher -s $sku --hyper-v-generation $hyper_v \
                --query 'id' -o tsv
  img_def_id=$(az sig image-definition list -r $sig_name -g $resource_group --query "[?name=='$image_name'].id" -o tsv)
else
  echo "Image definition for $image_name found in gallery $sig_name"
fi

# Check if the version of the managed image (retrieved thru the tag) exists in the SIG, if not then push to the SIG
image_id=$(az image list -g $resource_group --query "[?name=='$image_name'].id" -o tsv)
image_version=$(az image show --id $image_id --query "tags.Version" -o tsv)

# Check if the image version exists in the SIG
echo "Looking for image $image_name version $image_version ..."
img_version_id=$(az sig image-version list  -r $sig_name -i $image_name -g $resource_group --query "[?name=='$image_version'].id" -o tsv)

if [ "$img_version_id" == "" ] || [ $FORCE -eq 1 ]; then
  # Create an image version Major.Minor.Patch with Patch=YYmmddHHMM
  #patch=$(date +"%g%m%d%H%M" | cut -c 1-9)
  #eval_str=".images[] | select(.name == "\"$image_name"\") | .version"
  #version=$(yq eval "$eval_str" $CONFIG_FILE)
  #version+=".$patch"
  # Image version is YYY.MMDD.HHMM
  version=$(date -u +"%Y.%m%d.%H%M")
  echo "Pushing version $version of $image_name in $sig_name"

  storage_type=$(az image show --id $image_id --query "storageProfile.osDisk.storageAccountType" -o tsv)
  location=$(jq -r '.var_location' $OPTIONS_FILE)

  az sig image-version create \
    --resource-group $resource_group \
    --gallery-name $sig_name \
    --gallery-image-definition $image_name \
    --gallery-image-version $version \
    --storage-account-type $storage_type \
    --location $location \
    --replica-count 1 \
    --managed-image $image_id \
    -o tsv

  # Tag the image with the version 
  echo "Tagging the source image with version $version and checksum $packer_md5"
  az image update --ids $image_id --tags Version=$version checksum=$packer_md5 -o tsv

  # Tag the os disk with version
  if [ "$KEEP_OS_DISK" == "true" ]; then
    echo "Tagging the os disk with version $version"
    os_disk_id=$(az disk list -g $resource_group --query "[?name=='$image_name'].id" -o tsv)
    az disk update --ids $os_disk_id --set tags.'Version'=$version -o tsv
  fi
else
  echo "Image $image_name version $image_version found in galley $sig_name" 
fi

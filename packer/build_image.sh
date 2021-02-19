#!/bin/bash
# Build an image with packer and the provided packer file
# There are 2 options for providing the SPN used by packer
#  - With environment variables like in github actions
#     * ARM_CLIENT_ID, ARM_CLIENT_SECRET and ARM_TENANT_ID
#  - Thru the spn.json config file
set -e
OPTIONS_FILE=options.json
FORCE=0
SPN_FILE=spn.json
CONFIG_FILE=../config.yml

if [ $# -lt 2 ]; then
  echo "Usage build_image.sh "
  echo "  Required arguments:"
  echo "    -i|--image <image_file.json> | image packer file"
  echo "   "
  echo "  Optional arguments:"
  echo "    -o|--options <options.json>  | file with options for packer generated in the build phase"
  echo "    -f|--force                   | overwrite existing image and always push a new version in the SIG"
  exit 1
fi

PACKER_OPTIONS="-timestamp-ui"
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
    *)
      shift
      ;;
  esac
done

if [ -z "$ARM_CLIENT_ID" ]; then
  # Need the SPN name to use
  spn_appname=$(jq -r '.spn_name' $SPN_FILE )
  echo "spn_appname=$spn_appname"
  # Need keyvault name where the SPN secret is stored
  key_vault=$(jq -r '.key_vault' $SPN_FILE )
  echo "key_vault=$key_vault"

  # Check that the key_vault exists
  az keyvault show -n $key_vault --output table 2>/dev/null
  if [ "$?" = "0" ]; then
      echo "keyvault $key_vault exists"
  else
      echo "keyvault $key_vault doesn't exists"
      exit 1
  fi

  # Retrieve the spn appId and tenantId
  spn=$(az ad sp show --id http://$spn_appname --query "[appId,appOwnerTenantId]" -o tsv)
  if [ "$spn" == "" ]; then
    echo "SPN $spn_appname doesn't exists" 
    exit 1
  fi
  appId=$(echo "$spn" | head -n1)
  tenantId=$(echo "$spn" | tail -n1)

  # Retrieve the secret from the keyvault
  secret=$(az keyvault secret show --name $spn_appname --vault-name $key_vault -o json | jq -r '.value')
  if [ "$secret" == "" ]; then
    echo "No secret stored in $key_vault for $spn_appname"
    exit 1
  fi

else
  echo "Using predefined ARM_* environment variables"
  appId=$ARM_CLIENT_ID
  tenantId=$ARM_TENANT_ID
  secret=$ARM_CLIENT_SECRET
fi

echo "appId=$appId"
echo "tenantId=$tenantId"

image_name=$(basename "$PACKER_FILE")
image_name="${image_name%.*}"

# check if image already exists
resource_group=$(jq -r '.var_resource_group' $OPTIONS_FILE)
image_id=$(az image list -g $resource_group --query "[?name=='$image_name'].id" -o tsv)

if [ "$image_id" == "" ] || [ $FORCE -eq 1 ]; then
  logfile="${PACKER_FILE%.*}.log"
  echo "Image $image_name not found in $resource_group, building it (writing log to $logfile)"
  packer build $PACKER_OPTIONS -var-file $OPTIONS_FILE \
    -var "var_tenant_id=$tenantId" \
    -var "var_client_id=$appId" \
    -var "var_client_secret=$secret" \
    -var "var_image=$image_name" \
    -var "var_img_version=$version" \
    $PACKER_FILE | tee $logfile

else
  echo "Image $image_name exists, skipping building the image"
fi

sig_name=$(jq -r '.var_sig_name' $OPTIONS_FILE)

# Create the image definition if it doesn't exists
img_def_id=$(az sig image-definition list -r $sig_name -g $resource_group --query "[?name=='$image_name'].id" -o tsv)
if [ "$img_def_id" == "" ]; then
  echo "Creating an image definition for $image_name"
  # Get the image definition from the config file
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

  img_def_id=$(az sig image-definition create -r $sig_name -i $image_name -g $resource_group \
                -f $offer --os-type $os_type -p $publisher -s $sku --hyper-v-generation $hyper_v \
                --query 'id' -o tsv)
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
  patch=$(date +"%g%m%d%H%M")
  eval_str=".images[] | select(.name == "\"$image_name"\") | .version"
  version=$(yq eval "$eval_str" $CONFIG_FILE)
  version+=".$patch"
  echo "Pushing version $version of $image_name in $sig_name"

  location=$(jq -r '.var_location' $OPTIONS_FILE)

  az sig image-version create \
    --resource-group $resource_group \
    --gallery-name $sig_name \
    --gallery-image-definition $image_name \
    --gallery-image-version $version \
    --storage-account-type "Premium_LRS" \
    --location $location \
    --replica-count 1 \
    --managed-image $image_id \
    -o tsv

  # Tag the image with the version 
  echo "Tagging the source image with version $version"
  az image update --ids $image_id --tags Version=$version -o tsv
else
  echo "Image $image_name version $image_version found in galley $sig_name" 
fi

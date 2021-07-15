#!/bin/bash

# Build the HPC infrastructure with Terraform.
# build.sh -a [plan, apply, destroy] -v <vars file> -f <folder>
#
AZHOP_CONFIG=config.yml
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#TFVARS_FILE=""
TF_FOLDER=$THIS_DIR/tf
TF_TARGET=
if [ $# -eq 0 ]; then
  echo "Usage build.sh "
  echo "  Required arguments:"
  echo "    -a|--action [plan, apply, destroy] "
  echo "   "
  echo "  Optional arguments:"
  echo "    -f|-folder <relative path> - relative folder name containing the terraform files, default is ./tf"
#  echo "    -t|--target <target_resource> - Terraform target resource and dependencies to deploy" 

  exit 1
fi

unset PARAMS
while (( "$#" )); do
  case "${1}" in
    -a|--action)
      TF_COMMAND=${2}
      shift 2
    ;;
    -f|-folder)
      TF_FOLDER=${THIS_DIR}/${2}
      shift 2
    ;;
    -t|--target)
      TF_TARGET=${2}
      shift 2
    ;;
    *)
      PARAMS+="${1} "
      shift
      ;;
  esac
done

TF_BACKEND_FILE=$TF_FOLDER/backend.tf
export TF_CLI_ARGS_apply="-auto-approve"
#export TF_LOG=INFO
#export TF_LOG_PATH=.terraform/terraform.log

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

get_arm_access_key

terraform -chdir=$TF_FOLDER init

# Accept Cycle marketplace image terms
cc_plan=$(yq eval '.cyclecloud.plan.name' $AZHOP_CONFIG)
if [ "$cc_plan" == "" ]; then
  cc_plan="cyclecloud-81"
fi
accepted=$(az vm image terms show --offer azure-cyclecloud --publisher azurecyclecloud --plan $cc_plan --query 'accepted' -o tsv)
if [ "$accepted" != "true" ]; then
  echo "Azure CycleCloud marketplace image terms are not accepted, accepting them now"
  az vm image terms accept --offer azure-cyclecloud --publisher azurecyclecloud --plan $cc_plan -o tsv
else
  echo "Azure CycleCloud marketplace image terms already accepted"
fi

# Get the current logged user
azure_user=$(az account show --query user.name -o tsv)
created_on=$(date -u)
echo "terraform -chdir=$TF_FOLDER $TF_COMMAND -parallelism=30 $PARAMS"
#  -target=$TF_TARGET \

terraform -chdir=$TF_FOLDER $TF_COMMAND -parallelism=30 \
  -var "CreatedBy=$azure_user" \
  -var "CreatedOn=$created_on" \
  $PARAMS

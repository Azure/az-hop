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

terraform -chdir=$TF_FOLDER init -upgrade

# Check config syntax
yamllint $AZHOP_CONFIG

# Accept Cycle marketplace image terms
cc_plan=$(yq eval '.cyclecloud.plan.name' $AZHOP_CONFIG)
if [ "$cc_plan" == "" ]; then
  cc_plan="cyclecloud8"
fi
accepted=$(az vm image terms show --offer azure-cyclecloud --publisher azurecyclecloud --plan $cc_plan --query 'accepted' -o tsv)
if [ "$accepted" != "true" ]; then
  echo "Azure CycleCloud marketplace image terms are not accepted, accepting them now"
  az vm image terms accept --offer azure-cyclecloud --publisher azurecyclecloud --plan $cc_plan -o tsv
else
  echo "Azure CycleCloud marketplace image terms already accepted"
fi

# Accept Lustre marketplace image terms
accepted=$(az vm image terms show --offer azurehpc-lustre --publisher azhpc --plan azurehpc-lustre-2_12 --query 'accepted' -o tsv)
if [ "$accepted" != "true" ]; then
  echo "Azure Lustre marketplace image terms are not accepted, accepting them now"
  az vm image terms accept --offer azurehpc-lustre --publisher azhpc --plan azurehpc-lustre-2_12 -o tsv
else
  echo "Azure Lustre marketplace image terms already accepted"
fi

if [ -e $THIS_DIR/tf/terraform.tfstate ] && [ $TF_FOLDER != $THIS_DIR/tf ]; then
  cp -u -f $THIS_DIR/tf/terraform.tfstate $TF_FOLDER
fi

# Inspired from https://github.com/aztfmod/rover/blob/4098ce32e46f854445ac85839125f21410b439fc/scripts/functions.sh#L807
# Retrieve under which identity we run
user_type=$(az account show --query user.type -o tsv)
export TF_VAR_tenant_id=$(az account show -o json | jq -r .tenantId)
subscription_id=$(az account show --query id -o tsv)
if [ ${user_type} == "user" ]; then
  unset ARM_TENANT_ID
  unset ARM_SUBSCRIPTION_ID
  unset ARM_CLIENT_ID
  unset ARM_CLIENT_SECRET
  unset ARM_USE_MSI
  export TF_VAR_logged_user_objectId=$(az ad signed-in-user show --query objectId -o tsv)
  logged_user_upn=$(az ad signed-in-user show --query userPrincipalName -o tsv)
  echo " - logged in Azure with User ${logged_user_upn}"
else
  unset TF_VAR_logged_user_objectId
  export clientId=$(az account show --query user.name -o tsv)
  case "${clientId}" in
      "systemAssignedIdentity")
          vmname=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-08-15" | jq -r '.compute.name')
          echo " - logged in Azure with System Assigned Identity from ${vmname}"
          export TF_VAR_logged_user_objectId=$(az resource list -n $vmname --query [*].identity.principalId --out tsv)
          export ARM_TENANT_ID=${TF_VAR_tenant_id}
          export ARM_SUBSCRIPTION_ID=${subscription_id}
          export ARM_USE_MSI=true
          logged_user_upn="${TF_VAR_logged_user_objectId} from ${vmname}"
          ;;
      "userAssignedIdentity")
          echo "userAssignedIdentity not supported; please use a systemAssignedIdentity or a Service Principal Name instead"
          exit 1
          ;;
      *)
          export TF_VAR_logged_user_objectId=$(az ad sp show --id ${clientId} --query objectId -o tsv)
          logged_user_upn=$(az ad sp show --id ${clientId} --query displayName -o tsv)
          echo " - logged in Azure with Service Principal Name ${logged_user_upn}"
          export ARM_TENANT_ID=${TF_VAR_tenant_id}
          export ARM_SUBSCRIPTION_ID=${subscription_id}
          ;;
  esac
fi
export TF_VAR_CreatedBy=${logged_user_upn}
echo "terraform -chdir=$TF_FOLDER $TF_COMMAND $PARAMS"

# -parallelism=30
TF_LOG="TRACE"
TF_LOG_PATH="$THIS_DIR/tf/terraform.log"
rm -f $TF_LOG_PATH
retries=1
do_retry=true
while (( $retries < 3 )) && [ "$do_retry" == "true" ]; do
  terraform -chdir=$TF_FOLDER $TF_COMMAND $PARAMS
  if [ $? -eq 0 ]; then
    do_retry=false
  else
    grep "RetryableError" $TF_LOG_PATH
    if [ $? -eq 0 ]; then
      echo "Retry $retries"
      retries=$((retries+1))
      sleep 10
    else
      do_retry=false
    fi
  fi
done


if [ -e $TF_FOLDER/terraform.tfstate ] && [ $TF_FOLDER != $THIS_DIR/tf ]; then
  cp -u -f $TF_FOLDER/terraform.tfstate $THIS_DIR/tf/terraform.tfstate
fi

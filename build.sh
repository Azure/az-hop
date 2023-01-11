#!/bin/bash

# Build the HPC infrastructure with Terraform.
# build.sh -a [plan, apply, destroy] -v <vars file> -f <folder>
#
AZHOP_CONFIG=config.yml
AZCLI_VERSION_MAJOR=2
AZCLI_VERSION_MINOR=37
AZCLI_VERSION_PATCH=0
AZCLI_VERSION="$AZCLI_VERSION_MAJOR.$AZCLI_VERSION_MINOR.$AZCLI_VERSION_PATCH"

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

# If an existing terraform state exists for a different resource group, then delete it.
if [ -e $THIS_DIR/tf/terraform.tfstate ]; then
  rg_in_state=$(jq -r '.resources[] | select(.type=="azurerm_resource_group") | .instances[] | .attributes.name' $THIS_DIR/tf/terraform.tfstate)
  rg_in_config=$(yq eval '.resource_group' $AZHOP_CONFIG)
  set +e
  echo $rg_in_state | grep -w -q $rg_in_config
  if [ $? -eq 1 ]; then
    echo "Deleting existing terraform state for resource group $rg_in_state"
    rm -rf $THIS_DIR/tf/terraform.tfstate
  else
    echo "Keep existing terraform state for resource group $rg_in_state"
  fi
  set -e
fi

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

function check_azcli_version {
  version=$(az --version | grep azure-cli | xargs | cut -d' ' -f 2)
  major=$(echo $version | cut -d'.' -f 1)
  minor=$(echo $version | cut -d'.' -f 2)
  patch=$(echo $version | cut -d'.' -f 3)

  if [ $major -lt $AZCLI_VERSION_MAJOR ]; then
    echo "azure-cli version $AZCLI_VERSION or higher is required"
    exit 1
  else
    if [ $minor -lt $AZCLI_VERSION_MINOR ]; then
      echo "azure-cli version $AZCLI_VERSION or higher is required"
      exit 1
    else
      if [ $patch -lt $AZCLI_VERSION_PATCH ]; then
        echo "azure-cli version $AZCLI_VERSION or higher is required"
        exit 1
      fi
    fi
  fi
}

check_azcli_version

get_arm_access_key

terraform -chdir=$TF_FOLDER init -upgrade

# Check config syntax
yamllint $AZHOP_CONFIG

# Accept Cycle marketplace image terms
# cc_plan=$(yq eval '.cyclecloud.plan.name' $AZHOP_CONFIG)
# if [ "$cc_plan" == "" ]; then
#   cc_plan="cyclecloud8"
# fi
# accepted=$(az vm image terms show --offer azure-cyclecloud --publisher azurecyclecloud --plan $cc_plan --query 'accepted' -o tsv)
# if [ "$accepted" != "true" ]; then
#   echo "Azure CycleCloud marketplace image terms are not accepted, accepting them now"
#   az vm image terms accept --offer azure-cyclecloud --publisher azurecyclecloud --plan $cc_plan -o tsv
# else
#   echo "Azure CycleCloud marketplace image terms already accepted"
# fi

# Accept Lustre marketplace image terms
accepted=$(az vm image terms show --offer azurehpc-lustre --publisher azhpc --plan azurehpc-lustre-2_12 --query 'accepted' -o tsv)
if [ "$accepted" != "true" ]; then
  echo "Azure Lustre marketplace image terms are not accepted, accepting them now"
  az vm image terms accept --offer azurehpc-lustre --publisher azhpc --plan azurehpc-lustre-2_12 -o tsv
else
  echo "Azure Lustre marketplace image terms already accepted"
fi

# Accept AlmaLinux marketplace image terms
accepted=$(az vm image terms show --offer almalinux-hpc --publisher almalinux --plan 8_5-hpc-gen2 --query 'accepted' -o tsv)
if [ "$accepted" != "true" ]; then
  echo "Azure AlmaLinux marketplace image terms are not accepted, accepting them now"
  az vm image terms accept --offer almalinux-hpc --publisher almalinux --plan 8_5-hpc-gen2 -o tsv
else
  echo "Azure AlmaLinux marketplace image terms already accepted"
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
  export TF_VAR_logged_user_objectId=$(az ad signed-in-user show --query id -o tsv)
  logged_user_upn=$(az ad signed-in-user show --query userPrincipalName -o tsv)
  echo " - logged in Azure with User ${logged_user_upn}"
else
  unset TF_VAR_logged_user_objectId
  export clientId=$(az account show --query user.name -o tsv)
  case "${clientId}" in
      "systemAssignedIdentity")
          mds=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-08-15")
          vmname=$(echo $mds | jq -r '.compute.name')
          rgname=$(echo $mds | jq -r '.compute.resourceGroupName')
          echo " - logged in Azure with System Assigned Identity from ${vmname}/${rgname}"
          export TF_VAR_logged_user_objectId=$(az resource list -n $vmname -g $rgname --query [*].identity.principalId --out tsv)
          if [ "$TF_VAR_logged_user_objectId" == "" ]; then
            export TF_VAR_logged_user_objectId=$(az resource list -n $vmname -g $rgname --query [*].identity.userAssignedIdentities.*.principalId --out tsv)
          fi
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
          export TF_VAR_logged_user_objectId=$(az ad sp show --id ${clientId} --query id -o tsv)
          logged_user_upn=$(az ad sp show --id ${clientId} --query displayName -o tsv)
          echo " - logged in Azure with Service Principal Name ${logged_user_upn}"
          export ARM_TENANT_ID=${TF_VAR_tenant_id}
          export ARM_SUBSCRIPTION_ID=${subscription_id}
          ;;
  esac
fi
export TF_VAR_CreatedBy=${logged_user_upn}
echo "terraform -chdir=$TF_FOLDER $TF_COMMAND $PARAMS"

# Retrieve on which cloud environment we run on
# env details from here: https://github.com/hashicorp/terraform-provider-azurerm/blob/main/vendor/github.com/Azure/go-autorest/autorest/azure/environments.go
# TODO: check az environmentName for AzureChina and AzureGerman
cloud_env="Public"
account_env=$(az account show | jq '.environmentName' -r)
case "$account_env" in
  AzureChinaCloud)
    export TF_VAR_AzureEnvironment=AZURECHINACLOUD
    export TF_VAR_KeyVaultSuffix=vault.azure.cn
    export TF_VAR_BlobStorageSuffix=blob.core.chinacloudapi.cn
    ;;
  AzureGermanCloud)
    export TF_VAR_AzureEnvironment=AZUREGERMANCLOUD
    export TF_VAR_KeyVaultSuffix=vault.microsoftazure.de
    export TF_VAR_BlobStorageSuffix=blob.core.cloudapi.de
    ;;
  AzureCloud)
    export TF_VAR_AzureEnvironment=AZUREPUBLICCLOUD
    export TF_VAR_KeyVaultSuffix=vault.azure.net
    export TF_VAR_BlobStorageSuffix=blob.core.windows.net
    ;;
  AzureUSGovernment)
    export TF_VAR_AzureEnvironment=AZUREUSGOVERNMENTCLOUD
    export TF_VAR_KeyVaultSuffix=vault.usgovcloudapi.net
    export TF_VAR_BlobStorageSuffix=blob.core.usgovcloudapi.net
    ;;
  *)
    echo "ERROR: Unknown Azure environment ${account_env}"
    exit 1
    ;;
esac


# -parallelism=30
set +e
export TF_LOG="INFO"
export TF_LOG_PATH="$THIS_DIR/tf/terraform.log"
rm -f $TF_LOG_PATH
retries=1
do_retry=true
exit_code=0
while (( $retries < 3 )) && [ "$do_retry" == "true" ]; do
  terraform -chdir=$TF_FOLDER $TF_COMMAND $PARAMS
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
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
exit $exit_code
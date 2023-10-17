#!/bin/bash
#set -x
# Build the HPC infrastructure with Terraform.
# build.sh -a [plan, apply, destroy] -v <vars file> -f <folder>
#
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AZHOP_CONFIG=config.yml
BICEP_ROOT=$THIS_DIR/bicep
ARM_ROOT=$THIS_DIR/marketplace/solution
AZCLI_VERSION_MAJOR=2
AZCLI_VERSION_MINOR=37
AZCLI_VERSION_PATCH=0
AZCLI_VERSION="$AZCLI_VERSION_MAJOR.$AZCLI_VERSION_MINOR.$AZCLI_VERSION_PATCH"

AZHOP_ROOT=$THIS_DIR
AZHOP_FROM=local
#TFVARS_FILE=""
TF_FOLDER=$THIS_DIR/tf
TF_TARGET=
VALIDATE_CONFIG=true
VERBOSE=0

function usage()
{
  echo "Usage build.sh "
  echo "  Required arguments:"
  echo "    -a|--action [plan, apply, destroy] - Destroy will not applied with Bicep"
  echo "   "
  echo "  Optional arguments:"
  echo "    -f|--folder <relative path>      - relative folder name containing the terraform files, default is ./tf"
  echo "    -l|--language <tf, bicep, arm>   - deployment language to use, default is tf. arm template will be generated from bicep"
  echo "    --no-validate                    - skip validation of config.yml"
}

#######################################################################################################################
#
#                       Terraform Helpers
#
#######################################################################################################################
function terraform_init()
{
  export TF_CLI_ARGS_apply="-auto-approve"
  #export TF_LOG=INFO
  #export TF_LOG_PATH=.terraform/terraform.log

  # As we don't managed TF state in blob don't call this
  #get_arm_access_key

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

  terraform -chdir=$TF_FOLDER init -upgrade

  if [ -e $THIS_DIR/tf/terraform.tfstate ] && [ $TF_FOLDER != $THIS_DIR/tf ]; then
    cp -u -f $THIS_DIR/tf/terraform.tfstate $TF_FOLDER
  fi

}

function terraform_run()
{
  # -parallelism=30
  set +e
  export TF_LOG="INFO"
  export TF_LOG_PATH="$THIS_DIR/tf/terraform.log"
  rm -f $TF_LOG_PATH

  echo "terraform -chdir=$TF_FOLDER $TF_COMMAND $PARAMS"
  terraform -chdir=$TF_FOLDER $TF_COMMAND $PARAMS
  export EXIT_CODE=$?

  if [ -e $TF_FOLDER/terraform.tfstate ] && [ $TF_FOLDER != $THIS_DIR/tf ]; then
    cp -u -f $TF_FOLDER/terraform.tfstate $THIS_DIR/tf/terraform.tfstate
  fi
}

# Set the ARM_ACCESS_KEY env variable to be used by TF to manage states in azure blobs backend
# The ./tf/backend.tf file contains the values of the storage ressource group, account and container to be used
function get_arm_access_key {
  TF_BACKEND_FILE=$TF_FOLDER/backend.tf

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

#######################################################################################################################
#
#                       Azure Functions
#
#######################################################################################################################
function get_azure_context()
{
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
            mds=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-08-15")
            vmname=$(echo $mds | jq -r '.compute.name')
            rgname=$(echo $mds | jq -r '.compute.resourceGroupName')
            echo " - logged in Azure with User Assigned Identity from ${vmname}/${rgname}"
            export TF_VAR_logged_user_objectId=$(az resource list -n $vmname -g $rgname --query [*].identity.userAssignedIdentities.*.principalId --out tsv)
            client_id=$(az vm identity show -g $rgname --n $vmname --query userAssignedIdentities.*.clientId -o tsv)
            export ARM_TENANT_ID=${TF_VAR_tenant_id}
            export ARM_CLIENT_ID=${client_id}
            export ARM_SUBSCRIPTION_ID=${subscription_id}
            export ARM_USE_MSI=true
            logged_user_upn="${TF_VAR_logged_user_objectId} from ${vmname}"
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
}

function get_storage_id {
  # get the storage account ID to use
  id=$(az storage account list -g $RESOURCE_GROUP --query "[?contains(@.name, 'storage')==\`true\`].id" | jq -r '.[0]')
  if [ ${id} == null ]; then
    echo "no storage account found to store the TF state"
    exit 1
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

function get_azure_cloud_env()
{
  # Retrieve on which cloud environment we run on
  # env details from here: https://github.com/hashicorp/terraform-provider-azurerm/blob/main/vendor/github.com/Azure/go-autorest/autorest/azure/environments.go
  # TODO: check az environmentName for AzureChina and AzureGerman
  cloud_env="Public"
  account_env=$(az account show --output json| jq '.environmentName' -r)
  case "$account_env" in
    # AzureChinaCloud)
    #   export TF_VAR_AzureEnvironment=AZURECHINACLOUD
    #   export TF_VAR_KeyVaultSuffix=vault.azure.cn
    #   export TF_VAR_BlobStorageSuffix=blob.core.chinacloudapi.cn
    #   ;;
    # AzureGermanCloud)
    #   export TF_VAR_AzureEnvironment=AZUREGERMANCLOUD
    #   export TF_VAR_KeyVaultSuffix=vault.microsoftazure.de
    #   export TF_VAR_BlobStorageSuffix=blob.core.cloudapi.de
    #   ;;
    AzureCloud)
      export TF_VAR_AzureEnvironment=AZUREPUBLICCLOUD
      # export TF_VAR_KeyVaultSuffix=vault.azure.net
      # export TF_VAR_BlobStorageSuffix=blob.core.windows.net
      ;;
    AzureUSGovernment)
      export TF_VAR_AzureEnvironment=AZUREUSGOVERNMENTCLOUD
      # export TF_VAR_KeyVaultSuffix=vault.usgovcloudapi.net
      # export TF_VAR_BlobStorageSuffix=blob.core.usgovcloudapi.net
      ;;
    *)
      echo "ERROR: Unknown Azure environment ${account_env}"
      exit 1
      ;;
  esac
}

#######################################################################################################################
#
#                       BICEP Helpers
#
#######################################################################################################################
function set_bicep_param_value()
{
  local Param=$1
  local Value=$2

  case $Value in
    "true"|"True")
      eval_str=". | $Param=true"
    ;;
    "false"|"False")
      eval_str=". | $Param=false"
    ;;
    *)
      eval_str=". | $Param=\$param"
    ;;

  esac

  jq "$eval_str" --arg param "$Value" $BICEP_PARAMS > $TMP_PARAMS
  cp $TMP_PARAMS $BICEP_PARAMS

}

function set_bicep_azhopconfig()
{
  jq '. | .parameters.azhopConfig.value=$json' --argjson json "$(yq $AZHOP_CONFIG -o json | jq '.' -c)" $BICEP_PARAMS > $TMP_PARAMS
  cp $TMP_PARAMS $BICEP_PARAMS
}

function arm_init()
{
  pushd $ARM_ROOT
  ./build.sh local
  popd
}


function bicep_init()
{
  # Build the parameters.json file based on the config file content
  location=$(yq '.location' $AZHOP_CONFIG)
  resource_group=$(yq '.resource_group' $AZHOP_CONFIG)
  adminuser=$(yq '.admin_user' $AZHOP_CONFIG)
  BICEP_PARAMS=$resource_group.parameters.json
  TMP_PARAMS=tmp.parameters.json
  AZHOP_DEPLOYMENT_OUTPUT=$resource_group.outputs.json

  # Set default param template file if it doesn't exists for the resource group
  if [ ! -e $BICEP_PARAMS ]; then 
    cp $BICEP_ROOT/param.json $BICEP_PARAMS
  fi

  if [ "$AZHOP_FROM" == "local" ]; then
    set_bicep_param_value ".parameters.loggedUserObjectId.value" "$TF_VAR_logged_user_objectId"
  fi

  set_bicep_param_value ".parameters.autogenerateSecrets.value" "false"
  set_bicep_param_value ".parameters.branchName.value" "$(git branch | grep "*" | cut -d' ' -f 2)"

  set_bicep_azhopconfig

  if [ "$AZHOP_FROM" == "deployer" ]; then
    # Change the jumpbox name to deployer if present
    sed -i 's/jumpbox/deployer/g' $BICEP_PARAMS

    # Add the logged user as a reader of the keyvault
    set_bicep_param_value ".parameters.azhopConfig.value.key_vault_readers" "$TF_VAR_logged_user_objectId"
  fi

  # Read secrets from the parameter file as we don't know the keyvault name until a proper deployment has been successful
  adminPassword=$(jq -r '.parameters.adminPassword.value' $BICEP_PARAMS)
  if [ "$adminPassword" == "null" ]; then
    set_bicep_param_value ".parameters.adminPassword.value" "$(openssl rand -base64 24)"
  fi
  databaseAdminPassword=$(jq -r '.parameters.databaseAdminPassword.value' $BICEP_PARAMS)
  if [ "$adminPassword" == "null" ]; then
    set_bicep_param_value ".parameters.databaseAdminPassword.value" "$(openssl rand -base64 24)"
  fi
  adminSshPublicKey=$(jq -r '.parameters.adminSshPublicKey.value' $BICEP_PARAMS)
  if [ "$adminSshPublicKey" == "null" ]; then
    # generate a new key if it doesn't exists
    if [ ! -e $AZHOP_ROOT/${adminuser}_id_rsa ]; then
      ssh-keygen -f $AZHOP_ROOT/${adminuser}_id_rsa  -N ""
    fi
    set_bicep_param_value ".parameters.adminSshPublicKey.value" "$(cat $AZHOP_ROOT/${adminuser}_id_rsa.pub)"
    set_bicep_param_value ".parameters.adminSshPrivateKey.value" "$(cat $AZHOP_ROOT/${adminuser}_id_rsa)"
  fi

}

function bicep_run()
{
  timestamp=$(date -u +"%Y.%m%d.%H%M%S")
  deployment_name=azhop_${timestamp}
  deployment_op="create"
  if [ "$TF_COMMAND" == "plan" ]; then
    deployment_op="what-if"
  fi

  if [ "$VERBOSE" == "1" ]; then
    az bicep build --file $BICEP_ROOT/mainTemplate.bicep --outfile mainTemplate.json
    cat mainTemplate.json
    az deployment sub validate --template-file $BICEP_ROOT/mainTemplate.bicep --location $location --parameters @$BICEP_PARAMS
  fi

  case $DEPLOY_LANGUAGE in
    "bicep")
      echo "* Deploying using Bicep"
      TEMPLATE_FILE=$BICEP_ROOT/mainTemplate.bicep
      ;;
    "arm")
      TEMPLATE_FILE=$ARM_ROOT/build_local/mainTemplate.json
      echo "* Deploying using ARM"
      ;;
  esac

  az deployment sub $deployment_op --template-file $TEMPLATE_FILE --location $location -n $deployment_name --parameters @$BICEP_PARAMS

  if [ "$TF_COMMAND" == "plan" ]; then
    exit
  fi

  echo "* Getting deployment output"
  az deployment group show \
      -g $resource_group \
      -n azhop \
      --query properties.outputs \
      > $AZHOP_DEPLOYMENT_OUTPUT

#  if [ "$AZHOP_FROM" == "local" ]; then

    # Update config path 
    jq '. | .azhopGlobalConfig.value.global_config_file=$param' --arg param $AZHOP_ROOT/config.yml $AZHOP_DEPLOYMENT_OUTPUT > $TMP_PARAMS
    cp $TMP_PARAMS $AZHOP_DEPLOYMENT_OUTPUT

    kv=$(jq -r .keyvaultName.value $AZHOP_DEPLOYMENT_OUTPUT)

    echo "* Getting keys from keyvault"
    az keyvault secret show --vault-name $kv -n ${adminuser}-pubkey --query "value" -o tsv > $AZHOP_ROOT/${adminuser}_id_rsa.pub
    az keyvault secret show --vault-name $kv -n ${adminuser}-privkey --query "value" -o tsv > $AZHOP_ROOT/${adminuser}_id_rsa
    chmod 600 $AZHOP_ROOT/${adminuser}_id_rsa*

    mkdir -p $AZHOP_ROOT/bin
    jq -r .azhopGetSecretScript.value $AZHOP_DEPLOYMENT_OUTPUT > $AZHOP_ROOT/bin/get_secret
    chmod +x $AZHOP_ROOT/bin/get_secret
    jq -r .azhopConnectScript.value $AZHOP_DEPLOYMENT_OUTPUT > $AZHOP_ROOT/bin/connect
    chmod +x $AZHOP_ROOT/bin/connect

    mkdir -p $AZHOP_ROOT/playbooks/group_vars
    jq .azhopGlobalConfig.value $AZHOP_DEPLOYMENT_OUTPUT | yq -P > $AZHOP_ROOT/playbooks/group_vars/all.yml

    jq '.azhopInventory.value' $AZHOP_DEPLOYMENT_OUTPUT | yq -P > $AZHOP_ROOT/playbooks/inventory

    # substitute passwords into the file
    #  - __ADMIN_PASSWORD__
    admin_pass="$(az keyvault secret show --vault-name $kv -n ${adminuser}-password --query "value" -o tsv)"
    sed -i "s/__ADMIN_PASSWORD__/$(sed 's/[&/\]/\\&/g' <<< $admin_pass)/g" $AZHOP_ROOT/playbooks/inventory
    jq .azhopPackerOptions.value $AZHOP_DEPLOYMENT_OUTPUT > $AZHOP_ROOT/packer/options.json
#  fi
}


if [ $# -eq 0 ]; then
  usage
  exit 1
fi

unset PARAMS
DEPLOY_LANGUAGE=tf

while (( "$#" )); do
  case "${1}" in
    -a|--action)
      TF_COMMAND=${2}
      # verify that the action is either plan, apply or destroy
      if [ "$TF_COMMAND" != "plan" ] && [ "$TF_COMMAND" != "apply" ] && [ "$TF_COMMAND" != "destroy" ] && [ "$TF_COMMAND" != "import" ] && [ "$TF_COMMAND" != "state" ]; then
        echo "Invalid action $TF_COMMAND. Valid values are plan, apply or destroy"
        exit 1
      fi
      shift 2
    ;;
    -l|--language)
      DEPLOY_LANGUAGE=${2}
      # verify that the language is either tf or bicep
      if [ "$DEPLOY_LANGUAGE" != "tf" ] && [ "$DEPLOY_LANGUAGE" != "bicep" ] && [ "$DEPLOY_LANGUAGE" != "arm" ]; then
        echo "Invalid language $DEPLOY_LANGUAGE. Valid values are tf, bicep or arm"
        exit 1
      fi
      shift 2
    ;;
    -f|--folder)
      TF_FOLDER=${THIS_DIR}/${2}
      shift 2
    ;;
    --no-validate)
      VALIDATE_CONFIG=false
      shift 1
    ;;
    *)
      PARAMS+="${1} "
      shift
      ;;
  esac
done

# Check that action is set
if [ -z "$TF_COMMAND" ]; then
  echo "Action is required"
  usage
  exit 1
fi

if [ -d ${THIS_DIR}/miniconda ]; then
  echo "Activating conda environment"
  source ${THIS_DIR}/miniconda/bin/activate
fi

# Validate config against schema
if [ "$VALIDATE_CONFIG" = true ]; then
  $THIS_DIR/validate_config.sh $AZHOP_CONFIG
fi

check_azcli_version
case $DEPLOY_LANGUAGE in
  tf)
    terraform_init
    get_azure_context
    get_azure_cloud_env
    terraform_run
    ;;
  bicep)
    # If a Jumpbox VM is defined in the config file then assume it's a local deployment, otherwise it's done from the deployer VM
    jumpbox=$(yq '.jumpbox' $AZHOP_CONFIG)
    if [ "$jumpbox" == "null" ]; then
      AZHOP_FROM="deployer"
    else
      AZHOP_FROM="local"
    fi
    get_azure_context
    bicep_init
    bicep_run
    ;;
  arm)
    # ARM deployment is always using a deplpyed VM
    AZHOP_FROM="deployer"
    arm_init
    get_azure_context
    bicep_init
    bicep_run
    ;;
esac


exit $EXIT_CODE

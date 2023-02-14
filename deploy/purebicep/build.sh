#!/bin/bash
# Build the azhop environment with bicep.
# build.sh -c|--config <configuration file path>
#
set -x
AZHOP_ROOT=../..
AZCLI_VERSION_MAJOR=2
AZCLI_VERSION_MINOR=37
AZCLI_VERSION_PATCH=0
AZCLI_VERSION="$AZCLI_VERSION_MAJOR.$AZCLI_VERSION_MINOR.$AZCLI_VERSION_PATCH"
AZHOP_FROM=local

set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

IS_DRY_RUN=0

if [ $# -eq 0 ]; then
  echo "Usage build.sh "
  echo "  Required arguments:"
  echo "    -c|--config <configuration file path> "
  echo "    -d|--dry-run "
  echo "   "

  exit 1
fi

while (( "$#" )); do
  case "${1}" in
    -c|--config)
      AZHOP_CONFIG=${2}
      shift 2
    ;;
    -d|--dry-run)
      IS_DRY_RUN=1
      shift
    ;;
  esac
done

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

function set_bicep_param_value()
{
  local Param=$1
  local Value=$2

  case $Value in
    "true"|"True")
      eval_str=". | $Param.value=true"
    ;;
    "false"|"False")
      eval_str=". | $Param.value=false"
    ;;
    *)
      eval_str=". | $Param.value=\$param"
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


check_azcli_version

# Check config syntax
yamllint $AZHOP_CONFIG
unset logged_user_objectId

# If a Jumpbox VM is defined in the config file then assume it's a local deployment, otherwise it's done from the deployer VM
jumpbox=$(yq '.jumpbox' $AZHOP_CONFIG)
if [ "$jumpbox" == "null" ]; then
  AZHOP_FROM="deployer"
else
  AZHOP_FROM="local"
fi

if [ "$AZHOP_FROM" == "local" ]; then
  # Inspired from https://github.com/aztfmod/rover/blob/4098ce32e46f854445ac85839125f21410b439fc/scripts/functions.sh#L807
  # Retrieve under which identity we run
  user_type=$(az account show --query user.type -o tsv)
  if [ ${user_type} == "user" ]; then
    export logged_user_objectId=$(az ad signed-in-user show --query id -o tsv)
    logged_user_upn=$(az ad signed-in-user show --query userPrincipalName -o tsv)
    echo " - logged in Azure with User ${logged_user_upn}"
  else
    unset logged_user_objectId
    export clientId=$(az account show --query user.name -o tsv)
    case "${clientId}" in
        "systemAssignedIdentity")
            mds=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-08-15")
            vmname=$(echo $mds | jq -r '.compute.name')
            rgname=$(echo $mds | jq -r '.compute.resourceGroupName')
            echo " - logged in Azure with System Assigned Identity from ${vmname}/${rgname}"
            export logged_user_objectId=$(az resource list -n $vmname -g $rgname --query [*].identity.principalId --out tsv)
            if [ "$logged_user_objectId" == "" ]; then
              export logged_user_objectId=$(az resource list -n $vmname -g $rgname --query [*].identity.userAssignedIdentities.*.principalId --out tsv)
            fi
            logged_user_upn="${logged_user_objectId} from ${vmname}"
            ;;
        "userAssignedIdentity")
            echo "userAssignedIdentity not supported; please use a systemAssignedIdentity or a Service Principal Name instead"
            exit 1
            ;;
        *)
            export logged_user_objectId=$(az ad sp show --id ${clientId} --query id -o tsv)
            logged_user_upn=$(az ad sp show --id ${clientId} --query displayName -o tsv)
            echo " - logged in Azure with Service Principal Name ${logged_user_upn}"
            ;;
    esac
  fi
fi

# Build the parameters.json file based on the config file content
location=$(yq '.location' $AZHOP_CONFIG)
resource_group=$(yq '.resource_group' $AZHOP_CONFIG)
adminuser=$(yq '.admin_user' $AZHOP_CONFIG)
BICEP_PARAMS=$resource_group.parameters.json
TMP_PARAMS=tmp.parameters.json
AZHOP_DEPLOYMENT_OUTPUT=$resource_group.outputs.json

# Set default param template file if it doesn't exists for the resource group
if [ ! -e $BICEP_PARAMS ]; then 
  cp param.json $BICEP_PARAMS
fi

if [ "$AZHOP_FROM" == "local" ]; then
  set_bicep_param_value ".parameters.loggedUserObjectId" "$logged_user_objectId"
fi

set_bicep_param_value ".parameters.autogenerateSecrets" "false"
set_bicep_param_value ".parameters.branchName" "$(git branch | grep "*" | cut -d' ' -f 2)"

set_bicep_azhopconfig

# Read secrets from the parameter file as we don't know the keyvault name until a proper deployment has been successful
adminPassword=$(jq -r '.parameters.adminPassword.value' $BICEP_PARAMS)
if [ "$adminPassword" == "null" ]; then
  set_bicep_param_value ".parameters.adminPassword" "$(openssl rand -base64 24)"
fi
databaseAdminPassword=$(jq -r '.parameters.databaseAdminPassword.value' $BICEP_PARAMS)
if [ "$adminPassword" == "null" ]; then
  set_bicep_param_value ".parameters.databaseAdminPassword" "$(openssl rand -base64 24)"
fi
adminSshPublicKey=$(jq -r '.parameters.adminSshPublicKey.value' $BICEP_PARAMS)
if [ "$adminSshPublicKey" == "null" ]; then
  # generate a new key if it doesn't exists
  if [ ! -e $AZHOP_ROOT/${adminuser}_id_rsa ]; then
    ssh-keygen -f $AZHOP_ROOT/${adminuser}_id_rsa  -N ""
  fi
  set_bicep_param_value ".parameters.adminSshPublicKey" "$(cat $AZHOP_ROOT/${adminuser}_id_rsa.pub)"
  set_bicep_param_value ".parameters.adminSshPrivateKey" "$(cat $AZHOP_ROOT/${adminuser}_id_rsa)"
fi

timestamp=$(date -u +"%Y.%m%d.%H%M")
deployment_name=azhop_${timestamp}
deployment_op="create"
if [ "$IS_DRY_RUN" == "1" ]; then
  deployment_op="what-if"
fi

az deployment sub $deployment_op --template-file mainTemplate.bicep --location $location -n $deployment_name --parameters @$BICEP_PARAMS

if [ "$IS_DRY_RUN" == "1" ]; then
  exit
fi

echo "* Getting deployment output"
az deployment group show \
    -g $resource_group \
    -n azhop \
    --query properties.outputs \
    > $AZHOP_DEPLOYMENT_OUTPUT

if [ "$AZHOP_FROM" == "local" ]; then

  # Update config path 
  jq '. | .azhopGlobalConfig.value.global_config_file=$param' --arg param $(pwd)/../../config.yml $AZHOP_DEPLOYMENT_OUTPUT > $TMP_PARAMS
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

  jq '.azhopInventory.value.all.hosts *= (.lustre_oss_private_ips.value | to_entries | map({("lustre-oss-" + (.key | tostring)): {"ansible_host": .value}}) | add // {}) | .azhopInventory.value' $AZHOP_DEPLOYMENT_OUTPUT | yq -P > $AZHOP_ROOT/playbooks/inventory

  jq .azhopPackerOptions.value $AZHOP_DEPLOYMENT_OUTPUT > $AZHOP_ROOT/packer/options.json
fi

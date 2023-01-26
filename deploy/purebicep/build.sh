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

set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -eq 0 ]; then
  echo "Usage build.sh "
  echo "  Required arguments:"
  echo "    -c|--config <configuration file path> "
  echo "   "

  exit 1
fi

while (( "$#" )); do
  case "${1}" in
    -c|--config)
      AZHOP_CONFIG=${2}
      shift 2
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

function convert_parameter()
{
  local configParam=$1
  local bicepParam=$2

  configValue=$(yq $configParam $AZHOP_CONFIG)

  set_bicep_param_value $bicepParam $configValue
}

function convert_object_parameter()
{
  local configParam=$1
  local bicepParam=$2

  configValue=$(yq $configParam $AZHOP_CONFIG -o json | jq '.' -c)
  set_bicep_object_value $bicepParam $configValue
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

function set_bicep_object_value()
{
  local Param=$1
  local Value=$2

  eval_str=". | $Param.value=\$param"

  jq "$eval_str" --argjson param "$Value" $BICEP_PARAMS > $TMP_PARAMS
  cp $TMP_PARAMS $BICEP_PARAMS
}

check_azcli_version

# Check config syntax
yamllint $AZHOP_CONFIG

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

# Build the parameters.json file based on the config file content
location=$(yq '.location' $AZHOP_CONFIG)
resource_group=$(yq '.resource_group' $AZHOP_CONFIG)
adminuser=$(yq '.admin_user' $AZHOP_CONFIG)
BICEP_PARAMS=$resource_group.parameters.json
TMP_PARAMS=tmp.parameters.json
AZHOP_DEPLOYMENT_OUTPUT=$resource_group.outputs.json

cp param.json $BICEP_PARAMS

set_bicep_param_value ".parameters.softwareInstallFromDeployer" "false"
set_bicep_param_value ".parameters.autogenerateSecrets" "false"
set_bicep_param_value ".parameters.logged_user_objectId" "$logged_user_objectId"
convert_parameter ".resource_group" ".parameters.azhopResourceGroupName"
convert_parameter ".admin_user" ".parameters.adminUser"
convert_parameter ".queue_manager" ".parameters.queue_manager"
convert_parameter ".locked_down_network.public_ip" ".parameters.publicIp"
convert_parameter ".jumpbox.ssh_port" ".parameters.deployer_ssh_port"
convert_object_parameter ".network.peering" ".parameters.vnetPeerings"

# Read secrets from the parameter file as we don't know the keyvault name until a proper deployment has been successful
adminPassword=$(jq -r '.parameters.adminPassword.value' $BICEP_PARAMS)
if [ "$adminPassword" == "null" ]; then
  set_bicep_param_value ".parameters.adminPassword" "$(openssl rand -base64 24)"
fi
slurmAccountingAdminPassword=$(jq -r '.parameters.slurmAccountingAdminPassword.value' $BICEP_PARAMS)
if [ "$adminPassword" == "null" ]; then
  set_bicep_param_value ".parameters.slurmAccountingAdminPassword" "$(openssl rand -base64 24)"
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

az deployment sub create --template-file mainTemplate.bicep --location $location --parameters @$BICEP_PARAMS

deployment_name=azhop

echo "* Getting deployment output"
az deployment group show \
    -g $resource_group \
    -n $deployment_name \
    --query properties.outputs \
    > $AZHOP_DEPLOYMENT_OUTPUT

# Update config path 
jq '. | .azhopGlobalConfig.value.global_config_file=$param' --arg param $(pwd)/../../config.yml $AZHOP_DEPLOYMENT_OUTPUT > $TMP_PARAMS
cp $TMP_PARAMS $AZHOP_DEPLOYMENT_OUTPUT

kv=$(jq -r .keyvaultName.value $AZHOP_DEPLOYMENT_OUTPUT)
adminuser=$(jq -r .azhopConfig.value.admin_user $AZHOP_DEPLOYMENT_OUTPUT)

echo "* Getting keys from keyvault"
az keyvault secret show --vault-name $kv -n ${adminuser}-pubkey --query "value" -o tsv > $AZHOP_ROOT/${adminuser}_id_rsa.pub
az keyvault secret show --vault-name $kv -n ${adminuser}-privkey --query "value" -o tsv > $AZHOP_ROOT/${adminuser}_id_rsa
chmod 600 $AZHOP_ROOT/${adminuser}_id_rsa*

echo "* Generating config files from templates"
# config.yml
jq .azhopConfig.value $AZHOP_DEPLOYMENT_OUTPUT | yq -P  > $AZHOP_ROOT/bicep_config.yml

mkdir -p $AZHOP_ROOT/bin
jq -r .azhopGetSecretScript.value $AZHOP_DEPLOYMENT_OUTPUT > $AZHOP_ROOT/bin/get_secret
chmod +x $AZHOP_ROOT/bin/get_secret
jq -r .azhopConnectScript.value $AZHOP_DEPLOYMENT_OUTPUT > $AZHOP_ROOT/bin/connect
chmod +x $AZHOP_ROOT/bin/connect

mkdir -p $AZHOP_ROOT/playbooks/group_vars
jq .azhopGlobalConfig.value $AZHOP_DEPLOYMENT_OUTPUT | yq -P > $AZHOP_ROOT/playbooks/group_vars/all.yml

jq '.azhopInventory.value.all.hosts *= (.lustre_oss_private_ips.value | to_entries | map({("lustre-oss-" + (.key + 1 | tostring)): {"ansible_host": .value}}) | add // {}) | .azhopInventory.value' $AZHOP_DEPLOYMENT_OUTPUT | yq -P > $AZHOP_ROOT/playbooks/inventory

jq .azhopPackerOptions.value $AZHOP_DEPLOYMENT_OUTPUT > $AZHOP_ROOT/packer/options.json

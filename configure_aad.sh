#!/bin/bash
# This script will register an AAD application used for OIDC and authentication. 
# The application secret is stored in the keyvault under a secret named azhop-oidc-password
set -e
AZHOP_CONFIG=config.yml
ANSIBLE_VARIABLES=playbooks/group_vars/all.yml
SECRET_NAME="azhop-oidc-password"

if [ ! -e $AZHOP_CONFIG ]; then
  echo "$AZHOP_CONFIG doesn't exist, exiting"
  exit 1
fi

key_vault=$(yq eval '.key_vault' $ANSIBLE_VARIABLES)
if [ "$key_vault" == "" ]; then
  echo "Keyvault retrieved from $ANSIBLE_VARIABLES is empty"
  exit 1
fi

aadName=$(yq eval '.resource_group' config.yml)
if [ "$aadName" == "" ]; then
  echo "Resource group retrieved from $ANSIBLE_VARIABLES is empty"
  exit 1
fi

azhop_uri=$(yq eval '.ondemand_fqdn' $ANSIBLE_VARIABLES)
if [ "$azhop_uri" == "" ]; then
  echo "ondemand_fqdn retrieved from $ANSIBLE_VARIABLES is empty"
  exit 1
fi

# Create the AAD application, generate a client secret, and register it with the AAD tenant
# Store the secret under <appId>-password in the keyvault
appId=$(az ad app list --display-name $aadName --query [].appId -o tsv)
if [ "$appId" == "" ]; then
  password=$(openssl rand -base64 20)
  current_password=$password
  az ad app create --display-name $aadName \
          --identifier-uris "https://$azhop_uri" \
          --reply-urls "https://$azhop_uri/oidc" \
          --required-resource-accesses @aad_manifest.json \
          --optional-claims @aad_claims.json \
          --key-type password \
          --password "$current_password" \
          --credential-description "azhop AAD" # Need to be <15 chars long https://github.com/Azure/azure-docs-powershell-azuread/issues/296
  appId=$(az ad app list --display-name $aadName --query [].appId -o tsv)
  SECRET_NAME="$appId-password"
  az keyvault secret set --value "$password" --name $SECRET_NAME --vault-name $key_vault -o table > /dev/null
else
  SECRET_NAME="$appId-password"
  echo "AAD application $aadName already exists"
  current_password=$(az keyvault secret list --vault-name $key_vault --query "[?name=='$SECRET_NAME'].name" -o tsv)
  if [ "$current_password" == "" ] ; then
    password=$(openssl rand -base64 20)
    current_password=$password
    az keyvault secret set --value "$password" --name $SECRET_NAME --vault-name $key_vault -o table > /dev/null
    echo "Generating a password for $aadName and storing it as secret $SECRET_NAME in keyvault $key_vault"
    az ad app update --id $appId --password "$current_password"
  else
    echo "$SECRET_NAME has already a secret stored in keyvault $key_vault"
  fi
fi

echo "AAD appId: $appId"

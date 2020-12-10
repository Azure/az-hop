#!/bin/bash
# Build an image with packer and the provided packer file
# There are 2 options for providing the SPN used by packer
#  - With environment variables like in github actions
#     * ARM_CLIENT_ID, ARM_CLIENT_SECRET and ARM_TENANT_ID
#  - Thru the spn.json config file

packer_file=$1
options_file=${2:-options.json}
spn_file=spn.json

if [ -z "$ARM_CLIENT_ID" ]; then
  # Need the SPN name to use
  spn_appname=$(jq -r '.spn_appname' $spn_file )
  echo "spn_appname=$spn_appname"
  # Need keyvault name where the SPN secret is stored
  key_vault=$(jq -r '.key_vault' $spn_file )
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

image_name=$(basename "$packer_file")
image_name="${image_name%.*}"

packer build -var-file $options_file \
  -var "var_tenant_id=$tenantId" \
  -var "var_client_id=$appId" \
  -var "var_client_secret=$secret" \
  -var "var_image=$image_name" \
  $packer_file

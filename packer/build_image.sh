#!/bin/bash
packer_file=$1
options_file=${2:-options.json}

# Need the SPN name to use
spn_appname=$(jq -r '.spn_name' $options_file )
echo "spn_appname=$spn_appname"
# Need keyvault name where the SPN secret is stored
key_vault=$(jq -r '.key_vault' $options_file )
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
echo "appId=$appId"
echo "tenantId=$tenantId"

# Retrieve the secret from the keyvault
secret=$(az keyvault secret show --name $spn_appname --vault-name $key_vault -o json | jq -r '.value')
if [ "$secret" == "" ]; then
  echo "No secret stored in $key_vault for $spn_appname"
  exit 1
fi

image_name=$(basename "$packer_file")
image_name="${image_name%.*}"

packer build -var-file $options_file \
  -var "var_tenant_id=$tenantId" \
  -var "var_client_id=$appId" \
  -var "var_client_secret=$secret" \
  -var "var_image=$image_name" \
  $packer_file

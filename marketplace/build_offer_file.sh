#!/bin/bash
set -e
set -o pipefail

offer=$1
os=$2

SA_ACCOUNT=azhop

os_disk_id=$(az disk list -g azhop_build_images --query "[?name=='${offer}-${os}'].id" -o tsv)
version=$(az disk show --id $os_disk_id --query "tags.Version" -o tsv)

echo "Check if version exists and if not then add a new one"

exists=$(jq '.definition.plans[] | select(.planId==$plan) | ."microsoft-azure-virtualmachines.vmImages" | has($version)' --arg plan ${os} --arg version ${version} ${offer}-${os}.json)
if [ "$exists" == "true" ]; then
    echo "Version $version of plan $os already exists, exiting"
    exit 
fi

start=$(date -u -d "-10 minutes" '+%Y-%m-%dT%H:%MZ')
expiry=$(date -u -d "+4 years" '+%Y-%m-%dT%H:%MZ') # 4 years expiration SAS

icon_sas=$(az storage container generate-sas --account-name $SA_ACCOUNT --name icons --permissions rl --start $start --expiry $expiry --output tsv)
image_sas=$(az storage container generate-sas --account-name $SA_ACCOUNT --name images --permissions rl --start $start --expiry $expiry --output tsv)

sasurl=$(echo "https://$SA_ACCOUNT.blob.core.windows.net/images/${offer}-${os}-v${version}.vhd?${image_sas}")

cat <<EOF >temp.json
{
    "$version": {
    "osVhdUrl": "$sasurl",
    "lunVhdDetails": []
    }
}
EOF

echo "Adding version $version to ${offer}-${os}"
cat temp.json

# For this plan
# Add the new version to the existing versions
jq '(.definition.plans[] | select(.planId==$plan)."microsoft-azure-virtualmachines.vmImages") += $version ' --arg plan ${os} --argjson version "$(jq '.' temp.json)" ${offer}-${os}.json > ${offer}-${os}-final.json

#fname=./offers/${offer}-${os}-final.json

#cp ./offers/${offer}-${os}.json $fname

#sed -i 's#INSERT_VHD_URL#'"$sasurl"'#g' $fname

# Don't bother with this as it will be done manually in the partner portal

# Add current subscription to the allowed ones
# tenantId=$(az account show | jq -r '.id')
# sed -i 's#INSERT_ALLOWED_SUBSCRIPTIONS#'"$tenantId"'#g' $fname

# # Add logo URLs
# for sz in small medium large wide; do

#     # get sas key from log and escape ampsand
#     sasurl=$(echo "https://$SA_ACCOUNT.blob.core.windows.net/icons/$offer/azhop-${offer}-${sz}.png?${icon_sas}" | sed 's/\&/\\\&/g')
#     sed -i 's#INSERT_'$(echo $sz | tr [:lower:] [:upper:])'_LOGO_URL#'"$sasurl"'#g' $fname

# done

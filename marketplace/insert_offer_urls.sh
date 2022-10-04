#!/bin/bash

offer=$1

SA_ACCOUNT=$2

start=$(date -u -d "-10 minutes" '+%Y-%m-%dT%H:%MZ')
expiry=$(date -u -d "+1 month" '+%Y-%m-%dT%H:%MZ')

icon_sas=$(az storage container generate-sas --account-name $SA_ACCOUNT --name icons --permissions rl --start $start --expiry $expiry --output tsv)
image_sas=$(az storage container generate-sas --account-name $SA_ACCOUNT --name images --permissions rl --start $start --expiry $expiry --output tsv)

fname=${offer}-offer-final.json

cp ${offer}-offer.json $fname

sasurl=$(echo "https://$SA_ACCOUNT.blob.core.windows.net/images/azhop-${offer}-centos-7.9-v1.0.0.vhd?${image_sas}" | sed 's/\&/\\\&/g')
sed -i 's#INSERT_VHD_URL#'"$sasurl"'#g' $fname

for sz in small medium large wide; do

    # get sas key from log and escape ampsand
    sasurl=$(echo "https://$SA_ACCOUNT.blob.core.windows.net/icons/$offer/azhop-${offer}-${sz}.png?${icon_sas}" | sed 's/\&/\\\&/g')
    sed -i 's#INSERT_'$(echo $sz | tr [:lower:] [:upper:])'_LOGO_URL#'"$sasurl"'#g' $fname

done

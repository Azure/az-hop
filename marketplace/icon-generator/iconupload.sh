#!/bin/bash

text=$1
SA_ACCOUNT=$2
SA_CONTAINER=$3

start=$(date -u -d "-10 minutes" '+%Y-%m-%dT%H:%MZ')
expiry=$(date -u -d "+1 week" '+%Y-%m-%dT%H:%MZ')

rw_sas=$(az storage container generate-sas --account-name $SA_ACCOUNT --name $SA_CONTAINER --permissions rwdl --start $start --expiry $expiry --output tsv)
ro_sas=$(az storage container generate-sas --account-name $SA_ACCOUNT --name $SA_CONTAINER --permissions rl --start $start --expiry $expiry --output tsv)

for f in azhop-${text}-*.png; do
    azcopy copy $f "https://$SA_ACCOUNT.blob.core.windows.net/$SA_CONTAINER/$text/?${rw_sas}"
    echo "https://$SA_ACCOUNT.blob.core.windows.net/$SA_CONTAINER/$text/$f?${ro_sas}"
done




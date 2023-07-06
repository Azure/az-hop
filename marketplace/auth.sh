#!/bin/bash
vault_name=$1
debug=1
creds=$(az keyvault secret show --query "value" --name marketplace-credentials --vault-name $vault_name -o tsv)

tenantId=$(echo $creds | jq -r .tenant)
appId=$(echo $creds | jq -r .appId)
password=$(echo $creds | jq -r .password)

req=
res=

print_last() {
    #echo "$req"
    echo "$res" | jq .
}

# legacy API
authenticate_legacy() {
    req='curl -s -d "grant_type=client_credentials&client_id=${appId}&client_secret=${password}&resource=https://cloudpartner.azure.com" -X POST https://login.microsoftonline.com/$tenantId/oauth2/token'
    res=$(eval $req)
    legacy_token=$(echo $res | jq -r .access_token)
    if [ ! $debug -eq 0 ]; then
        print_last
    fi
}

get_offers() {
    publisherId=${1:-""}
    req='curl -s -X GET "https://cloudpartner.azure.com/api/publishers/${publisherId}/offers?api-version=2017-10-31" -H "Authorization: Bearer $legacy_token" -H "accept: application/json"'
    res=$(eval $req)
    if [ ! $debug -eq 0 ]; then
        print_last
    fi
}

get_offer_by_id() {
    publisherId=${1:-""}
    offerId=${2:-""}
    req='curl -s -X GET "https://cloudpartner.azure.com/api/publishers/${publisherId}/offers/${offerId}?api-version=2017-10-31" -H "Authorization: Bearer $legacy_token" -H "accept: application/json"'
    res=$(eval $req)
    if [ ! $debug -eq 0 ]; then
        print_last
    fi
}

# PUT https://cloudpartner.azure.com/api/publishers/<publisherId>/offers/<offerId>?api-version=2017-10-31
put_offer() {
    publisherId=${1:-""}
    offerId=${2:-""}
    jsonFile=${3:=""}

    #curl -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $legacy_token" -d '{"key1":"value"}' "https://cloudpartner.azure.com/api/publishers/${publisherId}/offers/${offerId}?api-version=2017-10-31"
    req='curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $legacy_token" -d "$(<$jsonFile)" "https://cloudpartner.azure.com/api/publishers/${publisherId}/offers/${offerId}?api-version=2017-10-31"'

    res=$(eval $req)
    httpCode=$(jq -r '.[].httpStatusCode' <<< $res)
    if [ ! $debug -eq 0 ]; then
        print_last
    fi
    if [ "$httpCode" != "OK" ]; then
        exit 1
    fi
}

#!/bin/bash

debug=1

tenantId=$(jq -r .tenant creds.json)
appId=$(jq -r .appId creds.json)
password=$(jq -r .password creds.json)

req=
res=

print_last() {
    echo "$req"
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
    if [ ! $debug -eq 0 ]; then
        print_last
    fi
}

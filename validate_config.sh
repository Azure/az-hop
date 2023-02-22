#!/bin/bash
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG=${1:-${THIS_DIR}/config.yml}
SCHEMA=${THIS_DIR}/config.schema.json

function validate_config_yml {
    local config=$1
    # validate file against schema
    tmp_json=${config}.json
    yq $config -o json > $tmp_json
    set +e
    jsonschema --instance $tmp_json $SCHEMA
    retcode=$?
    set -e
    rm $tmp_json

    if [[ $retcode -ne 0 ]]; then 
        echo "$config fails validation"
        exit 1
    fi
    echo "$config passes validation"
}

yamllint $CONFIG
validate_config_yml $CONFIG

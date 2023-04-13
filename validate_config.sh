#!/bin/bash
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG=${1:-${THIS_DIR}/config.yml}
SCHEMA=${THIS_DIR}/config.schema.json

# validate that check-jsonschema is installed
if ! command -v check-jsonschema &> /dev/null
then
    echo "check-jsonschema could not be found"
    echo "Please update the toolchain by running: ./toolset/scripts/install.sh"
    exit 1
fi

function validate_config_yml {
    local config=$1
    # validate file against schema
    tmp_json=${config}.json
    yq $config -o json > $tmp_json
    set +e
    check-jsonschema --schemafile $SCHEMA $tmp_json
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

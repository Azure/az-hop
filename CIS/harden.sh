#!/bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
os=$1
lot=$2
azhop_playbooks=$THIS_DIR/../playbooks

function usage() {
    echo "Usage: $0 <os> <lot>"
    echo "  os: centos7 | centos8"
    echo "  lot: lot1 | lot2 | lot3"
    exit 1
}

if [ -z "$os" ]; then
    usage
fi

if [ -z "$lot" ]; then
    usage
fi

var_name=CIS_PLAYBOOK_DIR_${os}
if [ -z "${!var_name}" ]; then
  echo "The $var_name environment variable is not set. Please set (export $var_name=foo) it to the directory where the CIS playbooks for OS $os are stored."
  exit 1
fi

RULES=$THIS_DIR/$os/rules.yml
echo "Using CIS playbooks from ${!var_name}"

function appply_rules() {
    lot=$1
    echo "Applying tags for lot $lot"
    if [ -z "$lot" ]; then
      echo "No lot to apply"
      return
    fi

    # Get the rules for the lot
    if [ "$lot" == "all" ]; then
      eval_str=".rulesets[].rules"
    else
      eval_str=".rulesets[] | select(.name == "\"$lot"\").rules"
    fi

    readarray rules < <(yq eval "$eval_str" $RULES)
    if [ -z "$rules" ]; then
      echo "No rules found for lot $lot"
      exit 1
    fi

    echo "Applying rules for lot $lot"
    for rule in "${rules[@]}"; do
      tag=$(echo "$rule" | cut -d'-' -f 2)
      tags+="$tag,"
    done
    tags+="run_audit"

    echo "Applying tags: $tags"
    ansible-playbook -i $azhop_playbooks/inventory -i $azhop_playbooks/inventory.cis.yml $THIS_DIR/$os/main.yml --tags "$tags" -e "CIS_playbook_dir=${!var_name}"
}

appply_rules $lot

#!/bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

lot=$1
azhop_playbooks=$THIS_DIR/../playbooks

if [ -z "$CIS_PLAYBOOK_DIR" ]; then
  echo "The CIS_PLAYBOOK_DIR environment variable is not set. Please set it to the directory where the CIS playbooks are stored."
  exit 1
fi

RULES=$THIS_DIR/rules.yml

if [ -z "$lot" ]; then
  echo "Usage: $0 <lot to apply, all for all lots>"
  exit 1
fi

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
    ansible-playbook -i $azhop_playbooks/inventory -i $azhop_playbooks/inventory.cis.yml $THIS_DIR/site.yml --tags "$tags" -e "CIS_playbook_dir=$CIS_PLAYBOOK_DIR"
}

appply_rules $lot

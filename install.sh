#!/bin/bash
TARGET=${1:-all}
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLAYBOOKS_DIR=$THIS_DIR/playbooks
INVENTORY=$PLAYBOOKS_DIR/inventory

function run_playbook ()
{
  local playbook=$1
  local extra_vars_file=$2

  # If playbook marker doesn't exists, run it
  if [ ! -e $PLAYBOOKS_DIR/$playbook.ok ]; then
    local options=""
    if [ "$extra_vars_file" != "" ]; then
      options="--extra-vars=@$extra_vars_file"
    fi
    ansible-playbook -i $INVENTORY $PLAYBOOKS_DIR/$playbook.yml $options || exit 1
    touch $PLAYBOOKS_DIR/$playbook.ok
  else
    echo "Skipping playbook $PLAYBOOKS_DIR/$playbook.yml as it has been successfully run "
  fi
}

# Apply pre-reqs
$THIS_DIR/ansible_prereqs.sh

# Check config syntax
yamllint config.yml

case $TARGET in
  all)
    run_playbook ad
    run_playbook linux
    run_playbook add_users
    run_playbook lustre-sas
    run_playbook lustre
    run_playbook ccportal
    run_playbook ccpbs
    run_playbook scheduler
    run_playbook ood $PLAYBOOKS_DIR/ood-overrides.yml
    run_playbook grafana 
    run_playbook telegraf
    run_playbook chrony
  ;;
  lustre)
    run_playbook lustre-sas
    run_playbook lustre
  ;;
  ad | linux | add_users | ccportal | chrony | ccpbs | scheduler | grafana | telegraf)
    run_playbook $TARGET
  ;;
  ood)
    run_playbook ood $PLAYBOOKS_DIR/ood-overrides.yml
  ;;
  *)
    echo "unknown target"
    exit 1
  ;;
esac


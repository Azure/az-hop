#!/bin/bash
TARGET=${1:-all}
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLAYBOOKS_DIR=$THIS_DIR/playbooks
INVENTORY=$PLAYBOOKS_DIR/inventory
OOD_AUTH="basic"

function run_playbook ()
{
  local playbook=$1
  shift
  local extra_vars_file=$@

  # If playbook marker doesn't exists, run it
  if [ ! -e $PLAYBOOKS_DIR/$playbook.ok ]; then
    local options=""
    if [ "$extra_vars_file" != "" ]; then
      # Merge overrides variables in a single file
      yq eval-all '. as $item ireduce ({}; . *+ $item)' $extra_vars_file > $PLAYBOOKS_DIR/extra_vars.yml
      options+=" --extra-vars=@$PLAYBOOKS_DIR/extra_vars.yml"
    fi
    ansible-playbook -i $INVENTORY $PLAYBOOKS_DIR/$playbook.yml $options || exit 1
    if [ -e $PLAYBOOKS_DIR/extra_vars.yml ]; then
      rm $PLAYBOOKS_DIR/extra_vars.yml
    fi
    touch $PLAYBOOKS_DIR/$playbook.ok
  else
    echo "Skipping playbook $PLAYBOOKS_DIR/$playbook.yml as it has been successfully run "
  fi
}

function get_scheduler ()
{
  local scheduler
  scheduler=$(yq eval '.queue_manager' config.yml)
  if [ "$scheduler" == "null" ]; then
    scheduler="openpbs"
  fi

  SCHEDULER=$scheduler
  echo "Running on $SCHEDULER"
}

function get_ood_auth ()
{
  local ood_auth
  ood_auth=$(yq eval '.authentication.httpd_auth' config.yml)
  if [ "$ood_auth" == "null" ]; then
    ood_auth="basic"
  fi

  OOD_AUTH=$ood_auth
  echo "Authentication is $OOD_AUTH"
}

# Apply pre-reqs
$THIS_DIR/ansible_prereqs.sh

# Check config syntax
yamllint config.yml
get_scheduler
get_ood_auth

case $TARGET in
  all)
    run_playbook ad
    run_playbook linux
    run_playbook add_users
    run_playbook lustre-sas
    run_playbook lustre
    run_playbook ccportal
    run_playbook cccluster
    run_playbook scheduler
    run_playbook ood $PLAYBOOKS_DIR/ood-overrides-common.yml $PLAYBOOKS_DIR/ood-overrides-$SCHEDULER.yml $PLAYBOOKS_DIR/ood-overrides-auth-$OOD_AUTH.yml
    run_playbook ood-custom
    run_playbook grafana 
    run_playbook telegraf
    run_playbook chrony
  ;;
  lustre)
    run_playbook lustre-sas
    run_playbook lustre
  ;;
  ad | linux | add_users | ccportal | chrony | cccluster | scheduler | grafana | telegraf | ood-custom | winviz | remove_users)
    run_playbook $TARGET
  ;;
  ood)
    run_playbook ood $PLAYBOOKS_DIR/ood-overrides-common.yml $PLAYBOOKS_DIR/ood-overrides-$SCHEDULER.yml $PLAYBOOKS_DIR/ood-overrides-auth-$OOD_AUTH.yml
    run_playbook ood-custom
  ;;
  *)
    echo "unknown target"
    exit 1
  ;;
esac


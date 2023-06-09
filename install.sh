#!/bin/bash
TARGET=${1:-all}
shift
ANSIBLE_TAGS=$@
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLAYBOOKS_DIR=$THIS_DIR/playbooks
INVENTORY=$PLAYBOOKS_DIR/inventory
OOD_AUTH="basic"

load_miniconda() {
  # Note: packaging this inside a function to avoid forwarding arguments to conda
  if [ -d ${THIS_DIR}/miniconda ]; then
    echo "Activating conda environment"
    source ${THIS_DIR}/miniconda/bin/activate
  fi
}
load_miniconda

function run_playbook ()
{
  local playbook=$1
  shift
  local extra_vars_file=$@

  # If running all playbooks and playbook marker doesn't exists, run the playbook
  # If user requested specific playbook ignore marker file and force run
  if [ ! -e $PLAYBOOKS_DIR/$playbook.ok ] || [ "$TARGET" != "all" ]; then
    local options=""
    if [ "$extra_vars_file" != "" ]; then
      # Merge overrides variables in a single file
      yq eval-all '. as $item ireduce ({}; . *+ $item)' $extra_vars_file > $PLAYBOOKS_DIR/extra_vars.yml
      options+=" --extra-vars=@$PLAYBOOKS_DIR/extra_vars.yml"
    fi
    echo "Running playbook $PLAYBOOKS_DIR/$playbook.yml ..."
    ansible-playbook -i $INVENTORY $PLAYBOOKS_DIR/$playbook.yml $options $ANSIBLE_TAGS || exit 1
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

function enable_winviz ()
{
  local enable_winviz
  enable_winviz=$(yq eval '.enable_remote_winviz' config.yml)
  if [ "$enable_winviz" == "null" ]; then
    enable_winviz=false
  fi

  echo "Enable WinViz is $enable_winviz"
  if [ "$enable_winviz" == "true" ]; then
    ENABLE_WINVIZ_PLAYBOOK=$PLAYBOOKS_DIR/ood-overrides-guacamole.yml
  else
    touch $PLAYBOOKS_DIR/guac_spooler.ok
    ENABLE_WINVIZ_PLAYBOOK=
  fi
}

function enable_lustre ()
{
  FEATURE_LUSTRE_IN_CONFIG=$(yq eval '.lustre.create' config.yml)
  if [ "$FEATURE_LUSTRE_IN_CONFIG" != "null" ]; then
    ENABLE_LUSTRE=$(yq '.lustre.create' ./config.yml | tr '[:upper:]' '[:lower:]')
  else
    LUSTRE_VM_IN_CONFIG=$(yq eval '.lustre.oss_count' config.yml)
    if [ "$LUSTRE_VM_IN_CONFIG" == "null" ]; then
      ENABLE_LUSTRE=false
    else
      ENABLE_LUSTRE=true
    fi
  fi
  
  if [ "$ENABLE_LUSTRE" == "false" ]; then
    touch $PLAYBOOKS_DIR/lustre.ok
    touch $PLAYBOOKS_DIR/lustre-sas.ok
  fi
}

function use_existing_ad()
{
  local use_existing_ad
  use_existing_ad=$(yq eval '.domain.use_existing_dc' config.yml)
  if [ "$use_existing_ad" == "null" ]; then
    use_existing_ad=false
  fi

  if [ "$use_existing_ad" == "true" ]; then
    touch $PLAYBOOKS_DIR/ad.ok
    touch $PLAYBOOKS_DIR/add_users.ok
  fi

}

function use_local_users()
{
  local use_local_users
  use_local_users=$(yq eval '.authentication.user_auth' config.yml)
  if [ "$use_local_users" == "local" ]; then
    use_local_users=true
  fi

  if [ "$use_local_users" == "true" ]; then
    touch $PLAYBOOKS_DIR/ad.ok
    touch $PLAYBOOKS_DIR/add_users.ok
  else
    touch $PLAYBOOKS_DIR/add_local_users.ok
  fi
}

function use_grafana_telegraf()
{
  local use_grafana
  local use_telegraf
  use_grafana=$(yq eval '.monitoring.grafana' config.yml)
  use_telegraf=$(yq eval '.monitoring.telegraf' config.yml)
  
  if [ "$use_grafana" == "false" ]; then
    echo Skipping Grafana install
    touch $PLAYBOOKS_DIR/grafana.ok
  fi
  if [ "$use_telegraf" == "false" ]; then
    echo Skipping Telegraf install
    touch $PLAYBOOKS_DIR/telegraf.ok
  fi
}


# Ensure submodule exists
if [ ! -d "${PLAYBOOKS_DIR}/roles/ood-ansible/.github" ]; then
    printf "Installing OOD Ansible submodule\n"
    git submodule init
    git submodule update
fi

# Validate config against schema
$THIS_DIR/validate_config.sh config.yml

get_scheduler
get_ood_auth
enable_winviz
enable_lustre
use_existing_ad
use_local_users
use_grafana_telegraf

case $TARGET in
  all)
    run_playbook ad
    run_playbook dns
    run_playbook linux
    run_playbook grafana
    run_playbook lustre-sas
    run_playbook lustre
    run_playbook ccportal
    run_playbook add_users
    run_playbook add_local_users
    run_playbook cccluster
    run_playbook scheduler
    run_playbook ood $PLAYBOOKS_DIR/ood-overrides-common.yml $PLAYBOOKS_DIR/ood-overrides-$SCHEDULER.yml $PLAYBOOKS_DIR/ood-overrides-auth-$OOD_AUTH.yml $ENABLE_WINVIZ_PLAYBOOK
    run_playbook ood-custom
    run_playbook guacamole
    run_playbook guac_spooler
    run_playbook telegraf
    run_playbook chrony
  ;;
  lustre)
    run_playbook lustre-sas
    run_playbook lustre
  ;;
  ad | ad2 | linux | add_users | add_local_users | ccportal | chrony | cccluster | scheduler | grafana | telegraf | ood-custom | remove_users | tests | guacamole | guac_spooler | dns)
    run_playbook $TARGET
  ;;
  ood)
    run_playbook ood $PLAYBOOKS_DIR/ood-overrides-common.yml $PLAYBOOKS_DIR/ood-overrides-$SCHEDULER.yml $PLAYBOOKS_DIR/ood-overrides-auth-$OOD_AUTH.yml $ENABLE_WINVIZ_PLAYBOOK
    run_playbook ood-custom
  ;;
  *)
    echo "unknown target"
    exit 1
  ;;
esac


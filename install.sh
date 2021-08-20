#!/bin/bash
TARGET=${1:-all}
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$THIS_DIR/ansible_prereqs.sh

case $TARGET in
  all)
    ansible-playbook -i playbooks/inventory ./playbooks/ad.yml
    ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
    ansible-playbook -i playbooks/inventory ./playbooks/add_users.yml
    ansible-playbook -i playbooks/inventory ./playbooks/lustre-sas.yml
    ansible-playbook -i playbooks/inventory ./playbooks/lustre.yml
    ansible-playbook -i playbooks/inventory ./playbooks/ccportal.yml
    ansible-playbook -i playbooks/inventory ./playbooks/ccpbs.yml
    ansible-playbook -i playbooks/inventory ./playbooks/scheduler.yml
    ansible-playbook -i playbooks/inventory ./playbooks/ood.yml --extra-vars=@playbooks/ood-overrides.yml
    ansible-playbook -i playbooks/inventory ./playbooks/grafana.yml 
    ansible-playbook -i playbooks/inventory ./playbooks/telegraf.yml
    ansible-playbook -i playbooks/inventory ./playbooks/chrony.yml
  ;;
  lustre)
    ansible-playbook -i playbooks/inventory ./playbooks/lustre-sas.yml
    ansible-playbook -i playbooks/inventory ./playbooks/lustre.yml
  ;;
  ad | linux | add_users | ccportal | chrony | ccpbs | scheduler | grafana | telegraf)
    ansible-playbook -i playbooks/inventory ./playbooks/$TARGET.yml
  ;;
  ood)
    ansible-playbook -i playbooks/inventory ./playbooks/ood.yml --extra-vars=@playbooks/ood-overrides.yml
  ;;
  stage0)
    ./toolset/stages/stage0.sh
  ;;
  stage1)
    ./toolset/stages/stage1.sh
  ;;
  stage2)
    ./toolset/stages/stage2.sh
  ;;
  stage3)
    ./toolset/stages/stage3.sh
  ;;
  stage4)
    ./toolset/stages/stage4.sh
  ;;
  stage5)
    ./toolset/stages/stage5.sh
  ;;
  *)
    echo "unknown target"
    exit 1
  ;;
esac

#!/bin/bash
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$THIS_DIR/ansible_prereqs.sh

ansible-playbook -i playbooks/inventory ./playbooks/ad.yml
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
ansible-playbook -i playbooks/inventory ./playbooks/add_users.yml
ansible-playbook -i playbooks/inventory ./playbooks/ccportal.yml
ansible-playbook -i playbooks/inventory ./playbooks/scheduler.yml
ansible-playbook -i playbooks/inventory ./playbooks/ood.yml --extra-vars=@playbooks/ood-overrides.yml
ansible-playbook -i playbooks/inventory ./playbooks/grafana.yml 
ansible-playbook -i playbooks/inventory ./playbooks/telegraf.yml 

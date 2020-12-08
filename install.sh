#!/bin/bash
set -e

pip3 install pypsrp
pip3 install pysocks
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general

ansible-playbook -i playbooks/inventory ./playbooks/ad.yml
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
ansible-playbook -i playbooks/inventory ./playbooks/ccportal.yml
ansible-playbook -i playbooks/inventory ./playbooks/scheduler.yml
ansible-playbook -i playbooks/inventory ./playbooks/ood.yml --extra-vars=@playbooks/ood-overrides.yml
ansible-playbook -i playbooks/inventory ./playbooks/grafana.yml 
ansible-playbook -i playbooks/inventory ./playbooks/telegraf.yml 

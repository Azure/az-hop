#!/bin/bash

pip3 install pypsrp
pip3 install pysocks
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general

ansible-playbook -i playbooks/inventory ./playbooks/ad.yml

#!/bin/bash
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ `pip3 list pypsrp` == *"pypsrp"* ]]; then 
  echo pypsrp is already installed 
else
  pip3 install pypsrp
fi
if [[ `pip3 list PySocks` == *"PySocks"* ]]; then 
  echo PySocks is already installed 
else
  pip3 install PySocks
fi
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general

# This is to fix an issue when using delegate_to
if [ -f /usr/bin/python3 ] && [ ! -f /usr/bin/python ]; then 
  sudo ln --symbolic /usr/bin/python3 /usr/bin/python; 
fi

# Test if the ood-ansible repo has been pulled
OOD_ANSIBLE=$THIS_DIR/playbooks/roles/ood-ansible
if [ "$(ls -A $OOD_ANSIBLE)" ]; then
     echo "OOD Ansible playbook has been pulled"
else
    echo "$OOD_ANSIBLE is empty. Please git clone this repo using the --recursive option or run 'git submodule init && git submodule update'"
    exit 1
fi
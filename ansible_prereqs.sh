#!/bin/bash
set -e
ANSIBLE_VERSION_UBUNTU=5.8.0
ANSIBLE_VERSION_CENTOS=4.10.0

os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | xargs)
os_release=${os_release^^}

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
if [[ `pip3 list netaddr` == *"netaddr"* ]]; then 
  echo netaddr is already installed 
else
  pip3 install netaddr
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

ansible --version
pip3 list | grep ansible
version=$(pip3 list | grep ansible | sort | head -n 1 | xargs | cut -d' ' -f 2)
ANSIBLE_VERSION="ANSIBLE_VERSION_$os_release"
if [ "$version" != ${!ANSIBLE_VERSION} ]; then
  echo "Ansible version is ${!ANSIBLE_VERSION}. Please run ./toolset/scripts/install.sh to install the correct version of Ansible"
  exit 1
fi

#!/bin/bash
# Installs Ansible in a virtual environment
set -e
set -o pipefail

ANSIBLE_VERSION_UBUNTU=5.8.0
ANSIBLE_VERSION_CENTOS=4.10.0

# Version check
os_type=$(uname | awk '{print tolower($0)}')
echo $os_type
if [[ "$os_type" == "darwin" ]]; then
  ANSIBLE_VERSION=$ANSIBLE_VERSION_MACOS
elif [[ "$os_type" == "linux" ]]; then
  os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | xargs)
  os_release=${os_release^^}
  if [[ "$os_release" == "UBUNTU" ]]; then
    ANSIBLE_VERSION=$ANSIBLE_VERSION_UBUNTU
  elif [[ "$os_release" == "CENTOS" ]]; then
    ANSIBLE_VERSION=$ANSIBLE_VERSION_CENTOS
  else
    echo "Unsupported OS"
    exit 1
  fi
else
  echo "Unsupported OS"
  exit 1
fi

# Install Ansible and requirements in virtual environment
python3 -m venv venv
source venv/bin/activate

python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
echo $ANSIBLE_VERSION
if [[ "$os_type" == "darwin" ]]; then
    python3 -m pip install ansible
elif [[ "$os_type" == "linux" ]]; then
    python3 -m pip install ansible==${ANSIBLE_VERSION}
fi

# Install Ansible collections
echo "ANSIBLE_COLLECTIONS_PATHS=${ANSIBLE_COLLECTIONS_PATHS}"
ansible-galaxy collection install -r requirements.yml

# Install azhop dependencies
ansible-playbook -i playbooks/inventory playbooks/azhop-dependencies.yml

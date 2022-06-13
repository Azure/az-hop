#!/bin/bash
# Install basic command-line utilities
yum install -y epel-release

yum install -y \
     curl \
     python3 \
     python3-pip \
     jq \
     wget \
     git \
     yamllint

#
# Install AzCLI
#
echo "Installing AzCLI ..."
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/azure-cli.repo
yum install -y azure-cli

#
# Install AzCopy
#
echo "Installing AzCopy ..."
cd /usr/local/bin
wget -q https://aka.ms/downloadazcopy-v10-linux -O - | tar zxf - --strip-components 1 --wildcards '*/azcopy'
chmod 755 /usr/local/bin/azcopy 
#
# Install Ansible
#
echo "Installing Ansible ..."
yum remove -y ansible
pip3 install setuptools-rust
pip3 install --upgrade pip
pip3 install ansible==4.10.0

echo "Installing Ansible playbooks pre-reqs"
pip3 install pypsrp
pip3 install PySocks

ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general

#
# Install Terraform
#
echo "Installing terraform ..."
#apt update -y && \
#apt install -y software-properties-common && \
yum -y remove terraform
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
yum -y install terraform

#
# Install Packer
#
echo "Installing packer...."
yum remove packer -y
yum install -y packer

#
# Install yq
#
echo "Installing yq...."
VERSION=v4.13.3
BINARY=yq_linux_amd64
wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq && chmod +x /usr/bin/yq

# Clean-up
rm -f /tmp/*.zip && rm -f /tmp/*.gz && \

echo "=============="
echo "Python version"
echo "=============="
python3 --version
echo "==============="
echo "Ansible version"
echo "==============="
ansible --version
echo "================="
echo "Terraform version"
echo "================="
terraform --version
echo "=============="
echo "Packer version"
echo "=============="
/usr/bin/packer --version
echo "=========="
echo "AZ version"
echo "=========="
az --version
echo "=========="
echo "AZ Copy version"
echo "=========="
azcopy --version
echo "=========="
echo "yq version"
echo "=========="
yq --version
echo "End"
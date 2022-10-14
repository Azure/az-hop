#!/bin/bash

echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes
apt-get update
# Install basic command-line utilities
# --no-install-recommends \
apt install -y \
     sudo \
     curl \
     python3 \
     python3-pip \
     software-properties-common \
     apt-utils \
     jq \
     wget \
     git \
     dnsutils \
     yamllint \
     pwgen
#     ca-certificates \
#     file \
#     ftp \
#     gettext-base \
#     iproute2 \
#     iputils-ping \
#     libcurl4 \
#     libicu60 \
#     libunwind8 \
#     locales \
#     netcat \
#     openssh-client \
#     parallel \
#     rsync \
#     shellcheck \
#     sudo \
#     telnet \
#     time \
#     unzip \
#     upx \
#     zip \
#     tzdata && \

#
# Install AzCLI
#
echo "Installing AzCLI ..."
while ! which az >/dev/null 2>&1; do
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
done

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
apt-get remove ansible -y
apt autoremove
pip3 install ansible==5.8.0
#add-apt-repository --yes --update ppa:ansible/ansible
#apt install -y ansible

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
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository --yes "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get remove terraform -y
apt install -y terraform

#
# Install Packer
#
echo "Installing packer...."
apt-get remove packer -y
apt-get install packer

#
# Install yq
#
echo "Installing yq...."
VERSION=v4.25.3
BINARY=yq_linux_amd64
wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq && chmod +x /usr/bin/yq

# Clean-up
rm -f /tmp/*.zip && rm -f /tmp/*.gz && \

echo "=============="
echo "Python version"
echo "=============="
python3 --version || exit 1
echo "==============="
echo "Ansible version"
echo "==============="
ansible --version || exit 1
echo "================="
echo "Terraform version"
echo "================="
terraform --version || exit 1
echo "=============="
echo "Packer version"
echo "=============="
packer --version || exit 1
echo "=========="
echo "AZ version"
echo "=========="
az --version || exit 1
echo "=========="
echo "AZ Copy version"
echo "=========="
azcopy --version || exit 1
echo "=========="
echo "yq version"
echo "=========="
yq --version || exit 1
echo "End"
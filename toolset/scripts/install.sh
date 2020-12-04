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
     git
#     ca-certificates \
#     dnsutils \
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
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

#
# Install Ansible
#
echo "Installing Ansible ..."
apt install -y ansible

#
# Install Terraform
#
echo "Installing terraform ..."
#apt update -y && \
#apt install -y software-properties-common && \
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository --yes "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update -y
apt install -y terraform

#
# Install Packer
#
echo "Installing packer...."
apt-get install packer

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
packer --version
echo "=========="
echo "AZ version"
echo "=========="
az --version

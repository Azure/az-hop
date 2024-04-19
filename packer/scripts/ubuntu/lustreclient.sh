#!/bin/bash
LUSTRE_VERSION=2.15.4-42-gd6d405d

source /etc/lsb-release
echo "deb [arch=amd64] https://packages.microsoft.com/repos/amlfs-${DISTRIB_CODENAME}/ ${DISTRIB_CODENAME} main" | tee /etc/apt/sources.list.d/amlfs.list
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg

apt-get update
apt-get install -y amlfs-lustre-client-${LUSTRE_VERSION}=$(uname -r)

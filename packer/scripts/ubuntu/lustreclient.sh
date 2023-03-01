#!/bin/bash
LUSTRE_VERSION=2.15.1-24-gbaa21ca

source /etc/lsb-release
echo "deb [arch=amd64] https://packages.microsoft.com/repos/amlfs-${DISTRIB_CODENAME}/ ${DISTRIB_CODENAME} main" > /etc/apt/sources.list.d/amlfs.list
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
cp ./microsoft.gpg /etc/apt/trusted.gpg.d/

apt-get update
apt-get install -y amlfs-lustre-client-${LUSTRE_VERSION}=$(uname -r)

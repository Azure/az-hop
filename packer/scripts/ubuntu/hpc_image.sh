#!/bin/bash
set -e
# Update packages 
apt-get clean
apt-get update 

# Install git using ubuntu 
apt-get install -y git 

cd /mnt/

git clone https://github.com/Azure/azhpc-images -b ubuntu-hpc-20231127

sed -i 's/LUSTRE_VERSION=2.15.1-29-gbae0abe/LUSTRE_VERSION=2.15.4-42-gd6d405d/g' ./azhpc-images/ubuntu/common/install_lustre_client.sh

cd ./azhpc-images/ubuntu/ubuntu-20.x/ubuntu-20.04-hpc

./install.sh

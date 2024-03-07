#!/bin/bash
set -e
# Update packages 
apt-get clean
apt-get update 

# Install git using ubuntu 
apt-get install -y git 

cd /mnt/

git clone https://github.com/Azure/azhpc-images -b ubuntu-hpc-20231127

cd ./azhpc-images/ubuntu/ubuntu-20.x/ubuntu-20.04-hpc

./install.sh

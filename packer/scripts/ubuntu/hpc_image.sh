#!/bin/bash
set -e
# Update packages 
apt-get clean
apt-get update 

# Install git using ubuntu 
apt-get install -y git 

cd /mnt/

git clone https://github.com/Azure/azhpc-images -b ubuntu-hpc-20241023

sed -i 's/azcopyvnext.azureedge/azcopyvnext-awgzd8g7aagqhzhe.b02.azurefd/g' ./azhpc-images/common/install_azcopy.sh

cd ./azhpc-images/ubuntu/ubuntu-20.x/ubuntu-20.04-hpc

./install.sh

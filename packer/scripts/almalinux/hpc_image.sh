#!/bin/bash
set -e
yum install -y git

df -h

mkdir -p /mnt/resource
chmod 777 /mnt/resource
cd /mnt/resource

git clone https://github.com/Azure/azhpc-images # -b centos-hpc-20220112

cd ./azhpc-images/alma/alma-8.x/alma-8.6-hpc

./install.sh

#cd /mnt/resource/azhpc-images/tests/run-tests.sh --mofed-lts false

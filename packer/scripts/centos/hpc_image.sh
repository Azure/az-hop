#!/bin/bash
set -e
yum install -y git

chmod 777 /mnt/resource
cd /mnt/resource

git clone https://github.com/Azure/azhpc-images -b centos-hpc-20220112

cd ./azhpc-images/centos/centos-7.x/centos-7.9-hpc
./install.sh
cd /mnt/resource/azhpc-images/tests/run-tests.sh --mofed-lts false

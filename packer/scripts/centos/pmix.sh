#!/bin/bash

sudo yum install -y libevent-devel git flex autoconf

mkdir -p /opt/pmix/v3
cd /mnt
mkdir -p pmix
cd pmix
wget https://download.open-mpi.org/release/hwloc/v2.7/hwloc-2.7.1.tar.bz2
tar xf hwloc-2.7.1.tar.bz2
cd hwloc-2.7.1
./configure --prefix=/opt/pmix/v3
make -j
sudo make install
cd ..
git clone https://github.com/openpmix/openpmix.git openpmix
cd openpmix
git checkout v3.1
./autogen.sh
./configure --prefix=/opt/pmix/v3 --with-hwloc=/opt/pmix/v3
make -j
sudo make install

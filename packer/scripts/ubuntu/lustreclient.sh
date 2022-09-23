#!/bin/bash
lustre_version=${1:-b2_14}

apt-get update
apt-get install -y libyaml-dev
apt-get install -y module-assistant libreadline-dev libselinux-dev libsnmp-dev mpi-default-dev

echo "Downloading Lustre source code..."
cd /mnt
git clone git://git.whamcloud.com/fs/lustre-release.git
cd lustre-release

echo "Building Lustre client..."
git checkout $lustre_version
bash autogen.sh
./configure --with-o2ib=no --disable-server
make -j debs

echo "Installing Lustre client packages..."
dpkg -i debs/lustre-client-modules*deb 
dpkg -i debs/lustre-client-utils*deb


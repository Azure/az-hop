#!/bin/bash
# Based on: https://github.com/Azure/cyclecloud-slurm/blob/master/specs/default/cluster-init/files/00-build-slurm.sh
set -e

BUILD_DIR=/mnt/slurm
mkdir -p $BUILD_DIR

#
# Build PMIx
#
apt-get update
apt-get install -y git libevent-dev libhwloc-dev autoconf flex make gcc libxml2

cd $BUILD_DIR
mkdir -p /opt/pmix/v3
mkdir -p pmix/build/v3

cd pmix
git clone https://github.com/openpmix/openpmix.git source
cd source/
git branch -a
git checkout v3.1
git pull
./autogen.sh
cd ../build/v3/
../../source/configure --prefix=/opt/pmix/v3
make -j install

#
# Build SLURM
#

SLURM_VERSION=20.11.9
SLURM_FOLDER="slurm-${SLURM_VERSION}"
SLURM_PKG="slurm-${SLURM_VERSION}.tar.bz2"
DOWNLOAD_URL="https://download.schedmd.com/slurm"

cd $BUILD_DIR

apt-get install -y munge libmunge-dev libmysqlclient-dev libpam0g-dev
# yum install -y rpm-build munge-devel munge-libs readline-devel openssl openssl-devel pam-devel perl-ExtUtils-MakeMaker gcc mysql mysql-devel wget gtk2-devel.x86_64 glib2-devel.x86_64 libtool-2.4.2 m4 automake rsync

wget "${DOWNLOAD_URL}/${SLURM_PKG}"
tar xf ${SLURM_PKG}
cd $SLURM_FOLDER
# ./configure --prefix=/usr --with-pmix=/opt/pmix/v3 --sysconfdir=/etc/slurm --libdir=/usr/lib64
./configure --program-prefix= --prefix=/usr --exec-prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc/slurm --datadir=/usr/share --includedir=/usr/include --libdir=/usr/lib64 --libexecdir=/usr/libexec --localstatedir=/var --sharedstatedir=/var/lib --mandir=/usr/share/man --infodir=/usr/share/info --with-pmix=/opt/pmix/v3
make -j install

# Create slurmd service
cp etc/slurmd.service /usr/lib/systemd/system/

#
# The below is needed to CycleCloud chef recipe to work correctly
#

systemctl stop munge
userdel munge
rm -f /var/log/munge/munged.log
mkdir -p /etc/slurm

#
# Install Enroot
#

ENROOT_VERSION_FULL=${1:-3.4.0-2}
ENROOT_VERSION=${ENROOT_VERSION_FULL%-*}

# Debian-based distributions
arch=$(dpkg --print-architecture)
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.4.0/enroot_3.4.0-1_${arch}.deb
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.4.0/enroot+caps_3.4.0-1_${arch}.deb # optional
apt install -y ./*.deb

# # Install NVIDIA container support
# distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
#          && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
#          && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
#                sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
#                sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
# apt-get update
# sudo apt install -y curl gawk jq squashfs-tools parallel
# sudo apt install -y libnvidia-container-tools pigz squashfuse # optional

enroot version

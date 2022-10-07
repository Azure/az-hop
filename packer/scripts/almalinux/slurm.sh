#!/bin/bash
# Based on: https://github.com/Azure/cyclecloud-slurm/blob/master/specs/default/cluster-init/files/00-build-slurm.sh
set -e

SLURM_VERSION=20.11.9
BUILD_DIR=/mnt/slurm
mkdir -p $BUILD_DIR

#
# Build SLURM
#

SLURM_FOLDER="slurm-${SLURM_VERSION}"
SLURM_PKG="slurm-${SLURM_VERSION}.tar.bz2"
DOWNLOAD_URL="https://download.schedmd.com/slurm"

cd $BUILD_DIR

dnf -y install epel-release && dnf -q makecache
dnf -y install munge

if [ "$SLURM_VERSION" \> "20" ]; then
    PYTHON=python3
else
    PYTHON=python2
fi

dnf install -y dnf-plugins-core
dnf config-manager --set-enabled powertools

dnf install -y make $PYTHON which rpm-build munge-devel munge-libs readline-devel openssl openssl-devel pam-devel perl-ExtUtils-MakeMaker gcc mysql mysql-devel wget gtk2-devel.x86_64 glib2-devel.x86_64 libtool m4 automake rsync
if [ ! -e $BUILD_DIR/bin ]; then
    mkdir -p $BUILD_DIR/bin
fi

#
# Build PMIx
#
dnf -y install autoconf flex libevent-devel git
cd $BUILD_DIR
mkdir -p /opt/pmix/v3
mkdir -p pmix

git clone https://github.com/openpmix/openpmix.git openpmix
cd openpmix
git checkout v3.1
./autogen.sh
./configure --prefix=/opt/pmix/v3
make -j
make install

ln -s `which $PYTHON` $BUILD_DIR/bin/python
export PATH=$PATH:$BUILD_DIR/bin
wget "${DOWNLOAD_URL}/${SLURM_PKG}"
rpmbuild --define "_with_pmix --with-pmix=/opt/pmix/v3" -ta ${SLURM_PKG}

#
# Install SLURM
#

dnf -y install /root/rpmbuild/RPMS/x86_64/slurm-${SLURM_VERSION}*.rpm /root/rpmbuild/RPMS/x86_64/slurm-slurmd-${SLURM_VERSION}*.rpm

#
# The below is needed to CycleCloud chef recipe
#
systemctl stop munge
userdel munge
mkdir -p /etc/slurm

#
# Install Enroot
#

ENROOT_VERSION_FULL=${1:-3.4.0-2}
ENROOT_VERSION=${ENROOT_VERSION_FULL%-*}

arch=$(uname -m)
dnf install -y epel-release
rpm -q enroot || dnf install -y https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot-${ENROOT_VERSION_FULL}.el7.${arch}.rpm
rpm -q enroot+caps || dnf install -y https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot+caps-${ENROOT_VERSION_FULL}.el7.${arch}.rpm

# Install NVIDIA container support
#DIST=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/centos8/libnvidia-container.repo > /etc/yum.repos.d/libnvidia-container.repo

dnf -y makecache
dnf -y install libnvidia-container-tools

# Add kernel boot parameters
grep user.max_user_namespaces /etc/sysctl.conf || echo 'user.max_user_namespaces = 1417997' >> /etc/sysctl.conf
grep namespace.unpriv_enable /etc/default/grub || sed -i.bak 's/\(GRUB_CMDLINE_LINUX.*\)"$/\1 namespace.unpriv_enable=1 user_namespace.enable=1 vsyscall=emulate"/' /etc/default/grub
[ -e /boot/grub2/grub.cfg ] && grub2-mkconfig -o /boot/grub2/grub.cfg
[ -e /boot/efi/EFI/centos/grub.cfg ] && grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

enroot version

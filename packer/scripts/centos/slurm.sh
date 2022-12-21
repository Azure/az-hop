#!/bin/bash
# Based on: https://github.com/Azure/cyclecloud-slurm/blob/master/specs/default/cluster-init/files/00-build-slurm.sh
set -e

INSTALL_SLURM=no

SLURM_VERSION=20.11.9
BUILD_DIR=/mnt/slurm
mkdir -p $BUILD_DIR

#
# Build PMIx
#
yum -y install autoconf flex libevent-devel git libxml2

cd $BUILD_DIR
mkdir -p /opt/pmix/v3
mkdir -p pmix/build/v3 pmix/install/v3

# Need to update hwloc on Centos7
cd pmix
wget https://download.open-mpi.org/release/hwloc/v2.7/hwloc-2.7.1.tar.bz2
tar xf hwloc-2.7.1.tar.bz2
cd hwloc-2.7.1
./configure --prefix=/opt/pmix/v3
make -j
sudo make install
cd ..

git clone https://github.com/openpmix/openpmix.git source
cd source/
git branch -a
git checkout v3.1
git pull
./autogen.sh
cd ../build/v3/
../../source/configure --prefix=/opt/pmix/v3
make -j install >/dev/null
cd ../../install/v3/

if [ "$INSTALL_SLURM" = "yes" ]; then

    #
    # Build SLURM
    #

    SLURM_FOLDER="slurm-${SLURM_VERSION}"
    SLURM_PKG="slurm-${SLURM_VERSION}.tar.bz2"
    DOWNLOAD_URL="https://download.schedmd.com/slurm"

    cd $BUILD_DIR

    # munge is in EPEL
    yum -y install epel-release && yum -q makecache

    if [ "$SLURM_VERSION" \> "20" ]; then
        PYTHON=python3
    else
        PYTHON=python2
    fi

    yum install -y make $PYTHON which rpm-build munge-devel munge-libs readline-devel openssl openssl-devel pam-devel perl-ExtUtils-MakeMaker gcc mysql mysql-devel wget gtk2-devel.x86_64 glib2-devel.x86_64 libtool-2.4.2 m4 automake rsync
    mkdir -p $BUILD_DIR/bin

    ln -s `which $PYTHON` $BUILD_DIR/bin/python
    export PATH=$PATH:$BUILD_DIR/bin
    wget "${DOWNLOAD_URL}/${SLURM_PKG}"
    rpmbuild --define "_with_pmix --with-pmix=/opt/pmix/v3" -ta ${SLURM_PKG}

    #
    # Install SLURM
    #

    yum -y install /root/rpmbuild/RPMS/x86_64/slurm-${SLURM_VERSION}*.rpm /root/rpmbuild/RPMS/x86_64/slurm-slurmd-${SLURM_VERSION}*.rpm

    #
    # The below is needed to CycleCloud chef recipe
    #
    systemctl stop munge
    userdel munge
    mkdir -p /etc/slurm

fi

#
# Install Enroot
#

ENROOT_VERSION_FULL=${1:-3.4.0-2}
ENROOT_VERSION=${ENROOT_VERSION_FULL%-*}

arch=$(uname -m)
rpm -q enroot || yum install -y https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot-${ENROOT_VERSION_FULL}.el7.${arch}.rpm
rpm -q enroot+caps || yum install -y https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot+caps-${ENROOT_VERSION_FULL}.el7.${arch}.rpm

# # Install NVIDIA container support
# DIST=$(. /etc/os-release; echo $ID$VERSION_ID)
# curl -s -L https://nvidia.github.io/libnvidia-container/$DIST/libnvidia-container.repo > /etc/yum.repos.d/libnvidia-container.repo

# yum -y makecache
# yum -y install libnvidia-container-tools

# Add kernel boot parameters
grep user.max_user_namespaces /etc/sysctl.conf || echo 'user.max_user_namespaces = 1417997' >> /etc/sysctl.conf
grep namespace.unpriv_enable /etc/default/grub || sed -i.bak 's/\(GRUB_CMDLINE_LINUX.*\)"$/\1 namespace.unpriv_enable=1 user_namespace.enable=1 vsyscall=emulate"/' /etc/default/grub
[ -e /boot/grub2/grub.cfg ] && grub2-mkconfig -o /boot/grub2/grub.cfg
[ -e /boot/efi/EFI/centos/grub.cfg ] && grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg

enroot version

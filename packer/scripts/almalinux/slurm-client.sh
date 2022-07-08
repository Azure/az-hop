#!/bin/bash
# Based on: https://github.com/Azure/cyclecloud-slurm/blob/master/specs/default/cluster-init/files/00-build-slurm.sh
set -e

SLURM_VERSION=20.11.9
BUILD_DIR=/mnt/slurm
mkdir -p $BUILD_DIR

#
# Build PMIx
#
function build_pmix() {
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
}

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
dnf install -y make

dnf install -y make $PYTHON which rpm-build munge-devel munge-libs readline-devel openssl openssl-devel pam-devel perl-ExtUtils-MakeMaker gcc mysql mysql-devel wget gtk2-devel.x86_64 glib2-devel.x86_64 libtool m4 automake rsync
if [ ! -e $BUILD_DIR/bin ]; then
    mkdir -p $BUILD_DIR/bin
fi

build_pmix

ln -s `which $PYTHON` $BUILD_DIR/bin/python
export PATH=$PATH:$BUILD_DIR/bin
wget "${DOWNLOAD_URL}/${SLURM_PKG}"
rpmbuild --define "_with_pmix --with-pmix=/opt/pmix/v3" -ta ${SLURM_PKG}

# Download the job submit plugin
wget https://github.com/Azure/cyclecloud-slurm/releases/download/2.6.2/job_submit_cyclecloud_centos_20.11.7-1.so

#
# Install SLURM and plugin
#

dnf -y install /root/rpmbuild/RPMS/x86_64/slurm-${SLURM_VERSION}*.rpm /root/rpmbuild/RPMS/x86_64/slurm-slurmd-${SLURM_VERSION}*.rpm
cp job_submit_cyclecloud_centos_20.11.7-1.so /usr/lib64/slurm/job_submit_cyclecloud.so
chmod +x /usr/lib64/slurm/job_submit_cyclecloud.so

#
# The below is needed to CycleCloud chef recipe
#
systemctl stop munge
userdel munge
mkdir -p /etc/slurm

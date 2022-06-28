#!/bin/bash
# Based on: https://github.com/Azure/cyclecloud-slurm/blob/master/specs/default/cluster-init/files/00-build-slurm.sh
set -e

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

# Download the job submit plugin
wget https://github.com/Azure/cyclecloud-slurm/releases/download/2.6.2/job_submit_cyclecloud_centos_20.11.7-1.so

#
# Install SLURM and plugin
#

yum -y install /root/rpmbuild/RPMS/x86_64/slurm-${SLURM_VERSION}*.rpm /root/rpmbuild/RPMS/x86_64/slurm-slurmd-${SLURM_VERSION}*.rpm
cp job_submit_cyclecloud_centos_20.11.7-1.so /usr/lib64/slurm/job_submit_cyclecloud.so
chmod +x /usr/lib64/slurm/job_submit_cyclecloud.so

#
# The below is needed to CycleCloud chef recipe
#
systemctl stop munge
userdel munge
mkdir -p /etc/slurm

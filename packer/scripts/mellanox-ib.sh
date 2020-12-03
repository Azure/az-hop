#!/bin/bash
yum install python-devel redhat-rpm-config rpm-build gcc-gfortran fuse-libs -y
yum -y groupinstall "InfiniBand Support"
MLNX_OFED_PKG=MLNX_OFED_LINUX-4.9-0.1.7.0-rhel7.7-x86_64.tgz
KERNEL=$(uname -r)
wget http://content.mellanox.com/ofed/MLNX_OFED-4.9-0.1.7.0/${MLNX_OFED_PKG} -O /tmp/${MLNX_OFED_PKG}
tar zxf /tmp/${MLNX_OFED_PKG}
./MLNX_OFED_LINUX-4.9-0.1.7.0-rhel7.7-x86_64/mlnxofedinstall --kernel ${KERNEL} --kernel-sources /usr/src/kernels/${KERNEL} --add-kernel-support --skip-repo
rm -rf MLNX_OFED_LINUX-4.9-0.1.7.0-rhel7.7-x86_64; rm -rf /tmp/${MLNX_OFED_PKG}
sed -i -e 's/# OS.EnableRDMA=y/OS.EnableRDMA=y/g' /etc/waagent.conf
echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf

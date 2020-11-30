#!/bin/bash

yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
yum install -y cvmfs Lmod hwloc numactl
cvmfs_config setup
curl https://cvmfs.blob.core.windows.net/generic/generic.azure.conf -o /etc/cvmfs/config.d/generic.azure.conf
curl https://cvmfs.blob.core.windows.net/generic/generic.azure.pub -o /etc/cvmfs/keys/generic.azure.pub
echo 'export MODULEPATH=$(/usr/share/lmod/lmod/libexec/addto --append MODULEPATH /cvmfs/generic.azure/opt/modules)' > /etc/profile.d/z01_modulepath_cvmfs_generic.azure.sh

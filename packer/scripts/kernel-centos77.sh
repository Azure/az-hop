#!/bin/bash
yum install -y epel-release
yum install --releasever=7.7.1908 --disablerepo=openlogic -y kernel-devel-3.10.0-1062.12.1.el7.x86_64 kernel-headers-3.10.0-1062.12.1.el7.x86_64 kernel-tools-3.10.0-1062.12.1.el7.x86_64 dkms
wget https://aka.ms/lis
# wget https://download.microsoft.com/download/6/8/F/68FE11B8-FAA4-4F8D-8C7D-74DA7F2CFC8C/lis-rpms-4.3.5.x86_64.tar.gz 
tar xvzf lis
cd LISISO
./install.sh

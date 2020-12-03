#!/bin/bash
yum install -y epel-release
yum install --releasever=7.7.1908 --disablerepo=openlogic -y kernel-devel-3.10.0-1062.12.1.el7.x86_64 kernel-headers-3.10.0-1062.12.1.el7.x86_64 kernel-tools-3.10.0-1062.12.1.el7.x86_64 dkms
wget https://aka.ms/lis
tar xvzf lis
cd LISISO
./install.sh

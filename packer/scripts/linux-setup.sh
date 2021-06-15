#!/bin/bash

yum install -y sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python
yum install -y nfs-utils openssl-devel epel-release
yum install -y patch gcc gcc-c++ perl-Data-Dumper perl-Thread-Queue Lmod hwloc numactl jq htop python3 libXt

# Disable requiretty to allow run sudo within scripts
sed -i -e 's/Defaults    requiretty.*/ #Defaults    requiretty/g' /etc/sudoers

# disable selinux
setenforce 0
sed -i 's/SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config

cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
*               hard    nofile          65535
*               soft    nofile          65535
*               hard    stack           unlimited
*               soft    stack           unlimited
EOF

# Install azcopy
cd /usr/local/bin
wget -q https://aka.ms/downloadazcopy-v10-linux -O - | tar zxf - --strip-components 1 --wildcards '*/azcopy'
chmod 755 /usr/local/bin/azcopy

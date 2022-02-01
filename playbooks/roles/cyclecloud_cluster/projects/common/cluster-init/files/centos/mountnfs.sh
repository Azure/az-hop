#!/bin/bash
packages="nfs-utils"
homedir_mountpoint=$1
nfs_home_ip=$2
nfs_home_path=$3

if ! rpm -q $packages; then
  echo "Installing packages $packages"
  yum install -y $packages
fi

mkdir $homedir_mountpoint
echo "mount $nfs_home_ip:/$nfs_home_path $homedir_mountpoint"
mount $nfs_home_ip:/$nfs_home_path $homedir_mountpoint

setsebool -P use_nfs_home_dirs 1 || true

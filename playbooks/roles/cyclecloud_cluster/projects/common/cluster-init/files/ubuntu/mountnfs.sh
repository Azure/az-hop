#!/bin/bash
homedir_mountpoint=$1
nfs_home_ip=$2
nfs_home_path=$3
packages="nfs-common"

if ! dpkg -l $packages ; then
  echo "Installing packages $packages"
  apt-get install -y $packages
fi

mkdir $homedir_mountpoint
echo "mount $nfs_home_ip:/$nfs_home_path $homedir_mountpoint"
mount $nfs_home_ip:/$nfs_home_path $homedir_mountpoint

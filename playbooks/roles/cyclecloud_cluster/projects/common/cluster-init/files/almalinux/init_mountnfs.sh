#!/bin/bash
packages="nfs-utils"

if ! rpm -q $packages; then
  echo "Installing packages $packages"
  dnf install -y $packages
fi

setsebool -P use_nfs_home_dirs 1 || true

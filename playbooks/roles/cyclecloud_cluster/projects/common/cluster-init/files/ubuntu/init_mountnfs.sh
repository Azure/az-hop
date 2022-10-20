#!/bin/bash
packages="nfs-common"

if ! dpkg -l $packages ; then
  echo "Installing packages $packages"
  apt-get install -y $packages
fi


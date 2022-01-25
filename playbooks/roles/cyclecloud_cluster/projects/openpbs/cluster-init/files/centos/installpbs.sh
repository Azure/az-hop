#!/bin/bash
# install pbs rpms when not in custom image
if [ ! -f "/etc/pbs.conf" ]; then
  echo "Downloading PBS RPMs"
  wget -q https://github.com/PBSPro/pbspro/releases/download/v19.1.1/pbspro_19.1.1.centos7.zip
  unzip -o pbspro_19.1.1.centos7.zip
  echo "Installing PBS RPMs"
  yum install -y epel-release
  yum install -y pbspro_19.1.1.centos7/pbspro-execution-19.1.1-0.x86_64.rpm jq
fi

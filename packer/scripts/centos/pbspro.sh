#!/bin/bash

wget https://github.com/PBSPro/pbspro/releases/download/v19.1.1/pbspro_19.1.1.centos7.zip
unzip -o pbspro_19.1.1.centos7.zip
yum install epel-release -y
yum install -y pbspro_19.1.1.centos7/pbspro-execution-19.1.1-0.x86_64.rpm jq
rm -rf pbspro_19.1.1.centos7.zip
rm -rf pbspro_19.1.1.centos7


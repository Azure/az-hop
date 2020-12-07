#!/bin/bash

yum install -y https://packages.microsoft.com/yumrepos/cyclecloud/jetpack8-8.1.0-1275.x86_64.rpm
sed -i '46s/Error/Ok/' /opt/cycle/jetpack/system/embedded/lib/python3.8/site-packages/jetpack/admin_cli.py
systemctl enable jetpackd

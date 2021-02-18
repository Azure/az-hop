#!/bin/bash

yum install -y https://packages.microsoft.com/yumrepos/cyclecloud/jetpack8-8.1.0-1275.x86_64.rpm
sed -i '46s/Error/Ok/' /opt/cycle/jetpack/system/embedded/lib/python3.8/site-packages/jetpack/admin_cli.py
sed -i '263s/stdout=subprocess.PIPE/stdout=subprocess.PIPE, text=True/' /opt/cycle/jetpack/system/embedded/lib/python3.8/site-packages/healthcheck/healthservice.py
sed -i '46s/cwd=self.scratch/cwd=self.scratch, text=True/' /opt/cycle/jetpack/system/embedded/lib/python3.8/site-packages/healthcheck/check.py
sed -i '50s/stderr=subprocess.PIPE/stderr=subprocess.PIPE, text=True/' /opt/cycle/jetpack/system/embedded/lib/python3.8/site-packages/healthcheck/check.py
systemctl enable jetpackd

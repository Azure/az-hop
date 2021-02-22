#!/bin/bash

# fixing healthcheck on cc8
sed -i '263s/stdout=subprocess.PIPE)/stdout=subprocess.PIPE, text=True)/' /opt/cycle/jetpack/system/embedded/lib/python3.8/site-packages/healthcheck/healthservice.py
sed -i '46s/cwd=self.scratch)/cwd=self.scratch, text=True)/' /opt/cycle/jetpack/system/embedded/lib/python3.8/site-packages/healthcheck/check.py
sed -i '50s/stderr=subprocess.PIPE)/stderr=subprocess.PIPE, text=True)/' /opt/cycle/jetpack/system/embedded/lib/python3.8/site-packages/healthcheck/check.py

# enable the healthcheck on the node
cp ../files/check_stuff.sh /opt/cycle/jetpack/config/healthcheck.d/check_stuff.sh
cp ../files/healthchecks.json /opt/cycle/jetpack/config/healthchecks.json
chmod 777 /opt/cycle/jetpack/config/healthcheck.d/check_stuff.sh

systemctl restart healthcheck

# force run once on startup
source /opt/cycle/jetpack/system/bin/cyclecloud-env.sh
healthcheck



#!/bin/bash

# enable the healthcheck on the node
cp ../files/healthchecks.sh /opt/cycle/jetpack/config/healthcheck.d/healthchecks.sh
cp ../files/healthchecks.json /opt/cycle/jetpack/config/healthchecks.json
chmod 777 /opt/cycle/jetpack/config/healthcheck.d/healthchecks.sh

echo "Restarting healthcheck service"
systemctl restart healthcheck

# force run once on startup
source /opt/cycle/jetpack/system/bin/cyclecloud-env.sh

echo "Run healthcheck"
healthcheck

#!/bin/bash

# enable the healthcheck on the node
cp ../files/check_stuff.sh /opt/cycle/jetpack/config/healthcheck.d/check_stuff.sh
cp ../files/healthchecks.json /opt/cycle/jetpack/config/healthchecks.json
chmod 777 /opt/cycle/jetpack/config/healthcheck.d/check_stuff.sh

systemctl restart healthcheck

# force run once on startup
source /opt/cycle/jetpack/system/bin/cyclecloud-env.sh
healthcheck

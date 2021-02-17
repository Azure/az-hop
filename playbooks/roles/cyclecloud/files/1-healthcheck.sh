#!/bin/bash
# enable the healthcheck on the node

cp ../files/check_stuff.sh /opt/cycle/jetpack/config/healthcheck.d/check_stuff.sh
chmod 777 /opt/cycle/jetpack/config/healthcheck.d/check_stuff.sh




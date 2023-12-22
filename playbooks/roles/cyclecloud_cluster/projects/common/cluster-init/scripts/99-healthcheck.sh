#!/bin/bash

errormessage=$( /opt/azurehpc/test/azurehpc-health-checks/run-health-checks.sh -c /etc/nhc/nhc.conf 2>&1)
error=$?

# In case of health check failure, shutdown the node by calling the script /usr/libexec/nhc/azhop-node-offline.sh
if [ $error -eq 1 ]; then
    /usr/libexec/nhc/azhop-node-offline.sh $(hostname) "$errormessage"
    JETPACK=/opt/cycle/jetpack/bin/jetpack
    $JETPACK shutdown --unhealthy
fi

#!/bin/bash
# Don't run health checks if not enabled
enabled_nhc=$(jetpack config healthchecks.enabled | tr '[:upper:]' '[:lower:]')
if [[ $enabled_nhc != "true" ]]; then
    exit 0
fi
NHC_CONFIG_FILE="/etc/nhc/nhc.conf"

# if run-health-checks.sh exists, then runit
if [ -e /opt/azurehpc/test/azurehpc-health-checks/run-health-checks.sh ]; then
    errormessage=$( /opt/azurehpc/test/azurehpc-health-checks/run-health-checks.sh -c $NHC_CONFIG_FILE 2>&1)
    error=$?

    # In case of health check failure, shutdown the node by calling the script /usr/libexec/nhc/azhop-node-offline.sh
    if [ $error -eq 1 ]; then
        /usr/libexec/nhc/azhop-node-offline.sh $(hostname) "$errormessage"
        JETPACK=/opt/cycle/jetpack/bin/jetpack
        $JETPACK shutdown --unhealthy
    fi
else
    echo "ERROR: /opt/azurehpc/test/azurehpc-health-checks/run-health-checks.sh does not exist"
    exit 1
fi

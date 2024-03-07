#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
JETPACK=/opt/cycle/jetpack/bin/jetpack

# Don't run health checks if not enabled
enabled_nhc=$($JETPACK config healthchecks.enabled | tr '[:upper:]' '[:lower:]')
if [[ $enabled_nhc != "true" ]]; then
    exit 0
fi

# if run-health-checks.sh exists, then runit
if [ -e /opt/azurehpc/test/azurehpc-health-checks/run-health-checks.sh ]; then
    . /etc/os-release
    case $ID in
        ubuntu)
            LIBEXEDIR=/usr/lib;;
        *) 
            LIBEXEDIR=/usr/libexec;;
    esac
    NHC_COMMON_FILE=$SCRIPT_DIR/../files/nhc/nhc_common.conf
    export OFFLINE_NODE=$LIBEXEDIR/nhc/azhop-node-offline.sh
    export ONLINE_NODE=$LIBEXEDIR/nhc/node-mark-online

    errormessage=$( /opt/azurehpc/test/azurehpc-health-checks/run-health-checks.sh -e $NHC_COMMON_FILE 2>&1)
    error=$?

    # In case of health check failure, shutdown the node by calling the script /usr/libexec/nhc/azhop-node-offline.sh
    if [ $error -eq 1 ]; then
        $OFFLINE_NODE $(hostname) "$errormessage"
        $JETPACK shutdown --unhealthy
    fi
else
    echo "ERROR: /opt/azurehpc/test/azurehpc-health-checks/run-health-checks.sh does not exist"
    exit 1
fi

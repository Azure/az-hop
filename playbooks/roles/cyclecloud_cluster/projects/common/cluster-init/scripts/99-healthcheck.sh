#!/bin/bash

/usr/sbin/nhc -d

# In case of health check failure, shutdown the node
if [ $? -eq 1 ]; then
    JETPACK=/opt/cycle/jetpack/bin/jetpack
    $JETPACK shutdown --unhealthy
fi

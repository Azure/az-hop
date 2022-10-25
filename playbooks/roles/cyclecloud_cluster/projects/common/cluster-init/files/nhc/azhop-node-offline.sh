#!/bin/bash
# This code is executed when NHC detects an error
# Logs following information in CC log and requests CC to terminate the node:
#    Hostname
#    Physical host name
#    NHC error message

echo "`date '+%Y%m%d %H:%M:%S'` $0 $*"

HOSTNAME="$1"
shift
NOTE="$*"

PHYSICAL_HOST=$(strings /var/lib/hyperv/.kvp_pool_3 | grep -A1 PhysicalHostName | head -n 2 | tail -1)
JETPACK=/opt/cycle/jetpack/bin/jetpack

echo "$0:  ERROR : Node Health Checks failed on $HOSTNAME - $PHYSICAL_HOST - $NOTE"
$JETPACK log "ERROR : Node Health Checks failed - $(hostname) - $PHYSICAL_HOST - $NOTE" --level error
$JETPACK shutdown --unhealthy

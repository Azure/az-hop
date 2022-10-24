#!/bin/bash
PHYSICAL_HOST=$(strings /var/lib/hyperv/.kvp_pool_3 | grep -A1 PhysicalHostName | head -n 2 | tail -1)
JETPACK=/opt/cycle/jetpack/bin/jetpack

function log()
{
    timestamp=$(date -u "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp $1" >> /opt/cycle/jetpack/logs/healthchecks.log
}

function nhc_run()
{
    log "Running NHC"
    /usr/sbin/nhc -d
    if [ $? -eq 1 ]; then
        #1>&2 echo "ERROR : Node Health Checks failed - $(hostname) - $PHYSICAL_HOST"
        $JETPACK log "ERROR : Node Health Checks failed - $(hostname) - $PHYSICAL_HOST" --level error
        $JETPACK shutdown --unhealthy
    fi
}

nhc_run

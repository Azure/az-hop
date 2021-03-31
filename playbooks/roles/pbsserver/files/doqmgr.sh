#!/bin/bash
#
# PBS/Scalelib Integration for az-hop.
# Create new vizq queue and update some default settings


#/opt/pbs/bin/qmgr -c 'set server managers = root@*'
#/opt/pbs/bin/qmgr -c 'set server query_other_jobs = true'
#/opt/pbs/bin/qmgr -c 'set server scheduler_iteration = 15'
#/opt/pbs/bin/qmgr -c 'set server flatuid = true'
/opt/pbs/bin/qmgr -c 'set server job_history_enable=true'

function create_resource() {
	/opt/pbs/bin/qmgr -c "list resource $1" >/dev/null  2>/dev/null   || \
	/opt/pbs/bin/qmgr -c "create resource $1 type=$2, flag=h"
}

#create_resource slot_type string
#create_resource group_id string
#create_resource ungrouped string
#create_resource instance_id string
create_resource machinetype string
#create_resource nodearray string
#create_resource disk size
#create_resource ngpus size

#/opt/pbs/bin/qmgr -c "set queue workq resources_default.ungrouped = false"
#/opt/pbs/bin/qmgr -c "set queue workq resources_default.place = scatter" # Default in scalelib is scatter:excl
/opt/pbs/bin/qmgr -c "set queue workq default_chunk.ungrouped = false"

#/opt/pbs/bin/qmgr -c "create queue htcq"
#/opt/pbs/bin/qmgr -c "set queue htcq queue_type = Execution"
#/opt/pbs/bin/qmgr -c "set queue htcq resources_default.ungrouped = true"
/opt/pbs/bin/qmgr -c "set queue htcq resources_default.place = pack" # Default in scalelib is free
#/opt/pbs/bin/qmgr -c "set queue htcq default_chunk.ungrouped = true"
#/opt/pbs/bin/qmgr -c "set queue htcq enabled = true"
#/opt/pbs/bin/qmgr -c "set queue htcq started = true"

/opt/pbs/bin/qmgr -c "create queue vizq"
/opt/pbs/bin/qmgr -c "set queue vizq queue_type = Execution"
/opt/pbs/bin/qmgr -c "set queue vizq resources_default.ungrouped = true"
/opt/pbs/bin/qmgr -c "set queue vizq resources_default.place = pack"
/opt/pbs/bin/qmgr -c "set queue vizq resources_default.slot_type = viz3d"
/opt/pbs/bin/qmgr -c "set queue vizq default_chunk.ungrouped = true"
/opt/pbs/bin/qmgr -c "set queue vizq enabled = true"
/opt/pbs/bin/qmgr -c "set queue vizq started = true"

#/opt/pbs/bin/qmgr -c "set sched only_explicit_psets=True"
#/opt/pbs/bin/qmgr -c "set sched do_not_span_psets=True"

# /opt/pbs/bin/qmgr -c "create hook autoscale"
# /opt/pbs/bin/qmgr -c "import hook autoscale application/x-python default /opt/cycle/jetpack/system/bootstrap/pbs/autostart_hook.py"
# /opt/pbs/bin/qmgr -c "import hook autoscale application/x-config default /opt/cycle/jetpack/system/bootstrap/pbs/autostart.json"
# /opt/pbs/bin/qmgr -c "set hook autoscale event = periodic"
/opt/pbs/bin/qmgr -c "set hook autoscale freq = 60"
# /opt/pbs/bin/qmgr -c "create hook cycle_sub_hook"
# /opt/pbs/bin/qmgr -c "set hook cycle_sub_hook event = queuejob"
# /opt/pbs/bin/qmgr -c "create hook cycle_sub_periodic_hook"
# /opt/pbs/bin/qmgr -c "set hook cycle_sub_periodic_hook event = periodic"
# /opt/pbs/bin/qmgr -c "set hook cycle_sub_periodic_hook freq = 15"
# /opt/pbs/bin/qmgr -c "import hook cycle_sub_hook application/x-python default /opt/cycle/jetpack/system/bootstrap/pbs/submit_hook.py"
# /opt/pbs/bin/qmgr -c "import hook cycle_sub_hook application/x-config default /opt/cycle/jetpack/system/bootstrap/pbs/submit_hook.json"
# /opt/pbs/bin/qmgr -c "import hook cycle_sub_periodic_hook application/x-python default /opt/cycle/jetpack/system/bootstrap/pbs/submit_hook.py"
# /opt/pbs/bin/qmgr -c "import hook cycle_sub_periodic_hook application/x-config default /opt/cycle/jetpack/system/bootstrap/pbs/submit_hook.json"


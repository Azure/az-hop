#!/bin/bash
set -e
cd 
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $THIS_DIR/pbs_helpers.sh
source ~/.bash_profile

function make_uuid_str {
    uuid_str=""
    if which uuidgen >/dev/null; then
        uuid_str="$(uuidgen | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
    else
        uuid_str="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
    fi
}

# Check homedir
echo "Check if /anfhome is mounted"
df | grep anfhome || exit 1

# Check PBS
export PBS_MAX_WALLTIME="00:20:00"
make_uuid_str
job_group=$uuid_str
echo "Check PBS"
echo "Run qstat"
qstat || exit 1

echo "Submit jobs"
submit_job $job_group 1 1 hb60rs ~/job.sh
submit_job $job_group 1 1 hc44rs ~/job.sh
submit_job $job_group 1 1 hb120rs_v2 ~/job.sh

echo "Wait for jobs"
wait_alljobs $job_group

echo "Run pbsnodes"
pbsnodes -avS || exit 1

echo "Get job status"
check_jobstatus $job_group

#!/bin/bash
# Define a very long maximum walltime
MAX_WALLTIME="24:00:00"
MAX_WAIT_TIME=3600

function check_scheduler()
{
    export MAX_WALLTIME="00:20:00"
    echo "Check SLURM"
    echo "Run sinfo"
    sinfo || exit 1
}

function wait_alljobs()
{
    local jobgroup=$1
    # Wait for all jobs to be finished
    local active_jobs=$(squeue -n $jobgroup --noheader | wc -l)
    wait_time=0
    while [ $active_jobs -ne 0 ] && [ $wait_time -lt $MAX_WAIT_TIME ]; do
        echo "There are $active_jobs active jobs"
        sleep 60
        wait_time=$((wait_time+60))
        active_jobs=$(squeue -n $jobgroup --noheader | wc -l)
    done

    if [ $wait_time -ge $MAX_WAIT_TIME ]; then
        echo "Timeout while waiting for jobs"
        sinfo -l
        sinfo -R
        squeue -l
        scancel -n $jobgroup
        exit 1
    fi

    echo "All jobs finished"
}

function check_jobstatus()
{
    local jobgroup=$1
    local failed_jobs=$(grep "ERROR" $jobgroup* | wc -l)
    if [ $failed_jobs != 0 ]; then
        echo "ERROR : Failure while running jobs"
        grep "ERROR" $jobgroup*.out
        exit 1
    fi
}

function list_nodes()
{
    sinfo -Nel
}

function submit_job()
{
    local job_name=$1
    local node_count=$2
    local ppn=$3
    local slot_type=$4
    shift; shift; shift; shift
    local script=$@
    local slurm_options=""

    if [ "$slot_type" == "viz3d" ]; then
        slurm_options=" --gpus=1"
    fi
    echo "job_name=$job_name; node_count=$node_count; ppn=$ppn; slot_type=$slot_type; script=$script"
    sbatch --job-name=$job_name \
           --nodes=$node_count \
           --ntasks-per-node=$ppn \
           --time=$MAX_WALLTIME \
           --partition=$slot_type \
           --output="%x-%j.out" \
           --error="%x-%j.out" \
           $slurm_options \
           $script

    if [ "$?" -ne "0" ]; then
        echo "Unable to submit job"
        exit 1
    fi
}

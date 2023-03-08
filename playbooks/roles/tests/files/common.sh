#!/bin/bash
[[ -n $PBS_NODEFILE ]] && { ISPBS=true; JOBID=$PBS_JOBID; }
[[ -n $SLURM_NODELIST ]] && { ISSLURM=true; JOBID=$SLURM_JOBID; }

get_vm_size()
{
    export VM_SIZE=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize' | tr '[:upper:]' '[:lower:]')
}

print_vm_type()
{
    get_vm_size
    echo "Running on $VM_SIZE"
}

init_modules()
{
    echo "Initializing modules"
    source /etc/profile.d/modules.sh
    module use /usr/share/Modules/modulefiles
    module avail
}

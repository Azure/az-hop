#!/bin/bash

#SBATCH --job-name drivaer
#SBATCH --partition=hb120v3
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=64

np=$SLURM_NTASKS
n=$SLURM_NNODES
ppn=$SLURM_CPUS_ON_NODE

# setup openfoam environment (from eessi)
source /cvmfs/pilot.eessi-hpc.org/versions/2021.12/init/bash
ml OpenFOAM/9-foss-2021a
source $FOAM_BASH

# select the tutorial to run (and give any args required for allrun)
tutorial_path=incompressible/simpleFoam/drivaerFastback
allrun_args="-c $np -m M"

# the location to run the copy of the tutorial
local_path=$HOME/openfoam_tutorial_runs
mkdir -p $HOME/$local_path

# create the case name - add size and date
casedir=$local_path/$(basename $tutorial_path)_${n}x${ppn}_$(date +%Y%m%d_%H%M%S)

cp -r $FOAM_TUTORIALS/$tutorial_path $casedir

pushd $casedir
# allow flags to be added to the mpirun command through FOAM_MPIRUN_FLAGS environment variable
sed -i '/RunFunctions/a source <(declare -f runParallel | sed "s/mpirun/SLURM_EXPORT_ENV=ALL mpirun \\\$FOAM_MPIRUN_FLAGS/g")' Allrun
# change the script to bash (as we are using bash features not necessarily available for just a sh session)
sed -i 's#/bin/sh#/bin/bash#g' Allrun

export FOAM_MPIRUN_FLAGS="-mca pml ucx $(env |grep 'WM_\|FOAM_' | cut -d'=' -f1 | sed 's/^/-x /g' | tr '\n' ' ') -x MPI_BUFFER_SIZE -x UCX_IB_MLX5_DEVX=n -x UCX_POSIX_USE_PROC_LINK=n -x PATH -x LD_LIBRARY_PATH"

./Allrun $allrun_args

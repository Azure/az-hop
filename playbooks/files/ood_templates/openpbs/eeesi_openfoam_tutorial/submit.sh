#!/bin/bash
#PBS -N drivaer
#PBS -l select=2:ncpus=64:mpiprocs=64:slot_type=hb120v3,place=scatter:excl
#PBS -k oed
#PBS -j oe
#PBS -l walltime=300

np=$(wc -l <$PBS_NODEFILE)
n=2 # TODO : Get this from PBS
ppn=64 # TODO : Get this from PBS

# setup openfoam environment (from eessi)
source /cvmfs/pilot.eessi-hpc.org/versions/2021.12/init/bash
ml OpenFOAM/9-foss-2021a
source $FOAM_BASH

# select the tutorial to run (and give any args required for allrun)
tutorial_path=incompressible/simpleFoam/drivaerFastback
allrun_args="-c $np -m M"

# the location to run the copy of the tutorial
local_path=$HOME/openfoam_tutorial_runs
mkdir -p $local_path

# create the case name - add size and date
casedir=$local_path/$(basename $tutorial_path)_${n}x${ppn}_$(date +%Y%m%d_%H%M%S)

cp -r $FOAM_TUTORIALS/$tutorial_path $casedir

pushd $casedir
# allow flags to be added to the mpirun command through FOAM_MPIRUN_FLAGS environment variable
sed -i '/RunFunctions/a source <(declare -f runParallel | sed "s/mpirun/mpirun \\\$FOAM_MPIRUN_FLAGS/g")' Allrun
# change the script to bash (as we are using bash features not necessarily available for just a sh session)
sed -i 's#/bin/sh#/bin/bash#g' Allrun

ranks_per_numa=30
export FOAM_MPIRUN_FLAGS="-mca pml ucx -hostfile $PBS_NODEFILE $(env |grep 'WM_\|FOAM_' | cut -d'=' -f1 | sed 's/^/-x /g' | tr '\n' ' ') -x MPI_BUFFER_SIZE -x UCX_POSIX_USE_PROC_LINK=n -x PATH -x LD_LIBRARY_PATH --map-by ppr:${ranks_per_numa}:numa"

# Decompress the geometry
gunzip constant/geometry/*
mv constant/geometry constant/triSurface
# Reconstruct the single partition after the solver has run
sed -i 's/# runApplication reconstructPar/runApplication reconstructPar/g' Allrun

./Allrun $allrun_args

# Create a file to load the model in Paraview
touch case.foam

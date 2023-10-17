#!/bin/bash
#PBS -N PingPong
#PBS -l select=2:ncpus=1:mpiprocs=1:slot_type=hpc
#PBS -k oed
#PBS -j oe
#PBS -l walltime=300

source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles

module load mpi/impi-2021

#export I_MPI_FABRICS="shm:ofi"
export I_MPI_DEBUG=5
#export FI_PROVIDER=mlx
export I_MPI_HYDRA_BOOTSTRAP=ssh

IMB_ROOT=$I_MPI_ROOT/bin

CORES=`cat $PBS_NODEFILE | wc -l`
echo "Running on $CORES cores"
mpirun -hostfile $PBS_NODEFILE -np $CORES -ppn 1 $IMB_ROOT/IMB-MPI1 PingPong
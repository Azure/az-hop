#!/bin/bash

source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles

module load mpi/impi-2021

#export I_MPI_FABRICS="shm:ofi"
export I_MPI_DEBUG=5
#export FI_PROVIDER=mlx
export I_MPI_HYDRA_BOOTSTRAP=ssh

IMB_ROOT=$I_MPI_ROOT/bin

mpirun -hostfile $PBS_NODEFILE -np 2 -ppn 1 $IMB_ROOT/IMB-MPI1 PingPong
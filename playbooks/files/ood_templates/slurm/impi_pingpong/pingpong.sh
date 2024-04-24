#!/bin/bash
#SBATCH -J PingPong
#SBATCH -N 2
#SBATCH --ntasks-per-node=1
#SBATCH -p hpc
#SBATCH -t 5
#SBATCH --export=NONE
#SBATCH --exclusive

source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles

module load mpi/impi-2021

export I_MPI_DEBUG=5
export I_MPI_HYDRA_BOOTSTRAP=slurm
export I_MPI_PORT_RANGE=59000:61000

echo "Running on $SLURM_NNODES nodes"
mpirun -ppn 1 IMB-MPI1 PingPong

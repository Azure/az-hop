#!/bin/bash
#SBATCH -J PingPong
#SBATCH -N 2
#SBATCH --ntasks-per-node=1
#SBATCH -p hc44rs
#SBATCH -t 5

source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles

module load mpi/impi-2021

echo "Running on $SLURM_NNODES nodes"
mpirun -ppn 1 IMB-MPI1 PingPong

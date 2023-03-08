#!/bin/bash
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${THIS_DIR}/common.sh
print_vm_type

init_modules

module load mpi/impi-2021

#export I_MPI_FABRICS="shm:ofi"
export I_MPI_DEBUG=5
#export FI_PROVIDER=mlx
export I_MPI_HYDRA_BOOTSTRAP=ssh
IMB_ROOT=$I_MPI_ROOT/bin
mpi_options=""
if [[ "$ISPBS" = true ]]; then
    mpi_options=" -hostfile $PBS_NODEFILE"
fi
mpirun $mpi_options -np 2 -ppn 1 $IMB_ROOT/IMB-MPI1 PingPong

module unload mpi/impi-2021
unset I_MPI_DEBUG
unset I_MPI_HYDRA_BOOTSTRAP


# module load mpi/hpcx
# IMB_ROOT=$HPCX_MPI_TESTS_DIR/imb
# mpi_options=" -bind-to core"
# mpi_options+=" -mca coll_hcoll_enable 1 -x HCOLL_ENABLE_MCAST_ALL=1"

# if [[ "$ISPBS" = true ]]; then
#     mpi_options+=" -hostfile $PBS_NODEFILE"
#     mpi_options+=" -npernode 1 -np 2"
# fi
# mpirun $mpi_options $IMB_ROOT/IMB-MPI1 PingPong

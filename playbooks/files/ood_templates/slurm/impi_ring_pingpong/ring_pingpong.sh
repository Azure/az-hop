#!/bin/bash
#SBATCH -J RingPingPong
#SBATCH -N 4
#SBATCH --ntasks-per-node=1
#SBATCH -p hpc
#SBATCH -t 5
#SBATCH --export=NONE

TYPE=latency

JOBID=$SLURM_JOBID

if [ $TYPE == "latency" ]; then
   MSGLOG="9:10"
elif [ $TYPE == "bandwidth" ]; then
   MSGLOG="22:24"
else
   echo "Error: Do not recognize MSGLOG option: $MSGLOG"
   exit 1
fi

source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles

module load mpi/impi-2021

#export I_MPI_FABRICS="shm:ofi"
export I_MPI_DEBUG=5
#export FI_PROVIDER=mlx

IMB_ROOT=$I_MPI_ROOT/bin

mpi_options="-np 2 -ppn 1"
host_option="-hosts"


# affinity
numactl_options=" numactl --cpunodebind 0"

hostlist=$(pwd)/hosts.$JOBID
scontrol show hostnames | sort -u > $hostlist

src=$(tail -n 1 $hostlist)
# -msglog 9:10 is for 512 and 1024 bytes message size only
for dst in $(<$hostlist); do
    mpirun $host_option $src,$dst \
        $mpi_options $numactl_options \
        $IMB_ROOT/IMB-MPI1 PingPong -msglog $MSGLOG > ${src}_to_${dst}_ringpingpong.$JOBID.log
    src=$dst
done

# clean up
rm $hostlist

if [ $TYPE == "latency" ]; then
echo "Ring Ping Pong Results (1024 bytes)"
printf "%-20s %-20s %10s\n" "Source" "Destination" "Time [usec]"
grep "^         1024 " *_ringpingpong.$JOBID.log \
    | tr -s ' ' | cut -d ' ' -f 1,4 \
    | sed 's/_to_/ /g;s/_ringpingpong[^:]*://g' \
    | sort -nk 3 \
    | xargs printf "%-20s %-20s %10s\n" | tee output.log
else
echo "Ring Ping Pong Bandwidth Results (16777216 bytes)"
printf "%-20s %-20s %10s\n" "Source" "Destination" "Mbytes/sec"
grep "^ *16777216 " *_ringpingpong.$JOBID.log \
    | tr -s ' ' | cut -d ' ' -f 1,5 \
    | sed 's/_to_/ /g;s/_ringpingpong[^:]*://g' \
    | sort -nk 3 \
    | xargs printf "%-20s %-20s %10s\n" | tee bandwidth_output.log
fi

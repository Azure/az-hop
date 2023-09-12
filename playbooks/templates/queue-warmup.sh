#!/bin/bash
# Usage: ./warmup-queues.sh viz hb2la
set -e

# SLURM node states & state flags on AZ-HOP

# idle   VM allocated and idling
# idle~  VM not allocated from Azure
# idle#  VM being allocated from Azure
# idle%  VM being powered down
# mix    Some CPUs allocated but not all

for queue in "$@"; do
  available=`sinfo -p $queue --states=mix,idle --noheader | grep -v idle~ | grep -v idle# | grep -v idle% | wc -l`
  allocating=`sinfo -p $queue --states=idle --noheader | grep idle# | wc -l`

  if [[ $available == 0 && $allocating == 0 ]]; then
    echo "Allocating 1 node on queue $queue"
    srun --partition $queue bash > /dev/null 2>&1 &
    PID=$!
    sleep 2
    set +e
    kill $PID
    set -e
  elif [[ $available -gt 0 ]]; then
    # "touch" one available node so that it won't be deallocated by slurm after timeout
    set +e
    srun --partition $queue "exit" > /dev/null 2>&1 &
    set -e
  fi
done

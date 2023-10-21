## OSU Benchmarks

### Start a shell session
### Start an interactive job on a compute node
```bash
qsub -l select=1:slot_type=hpc -I
```

### Load Spack environment and modules
```bash
. ~/spack/share/spack/setup-env.sh
module use /usr/share/Modules/modulefiles
```

### Install OSU benchmarks with Spack and OpenMPI
```bash
spack install osu-micro-benchmarks^openmpi
```

### Create a file named osu_benchmarks.sh with this content
```bash
#!/bin/bash
BENCH=${1:-osu_latency}
. ~/spack/share/spack/setup-env.sh
source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles
spack load osu-micro-benchmarks^openmpi
mpirun -x PATH --hostfile $PBS_NODEFILE --map-by ppr:1:node --bind-to core --report-bindings $BENCH
```

Grant execute right on the osu_benchmarks.sh

### Submit jobs on 2 nodes
```bash
qsub -N BW -joe -koe -l select=2:slot_type=hpc -- osu_benchmarks.sh osu_bw
qsub -N LAT -joe -koe -l select=2:slot_type=hpc -- osu_benchmarks.sh osu_latency
```

Wait for the jobs to be completed. Use CycleCloud to monitor the node provisioning if any.

```bash
qstat -fx <jobid>
pbsnodes -avS
```

### Job results are located in the BW.* and LAT.* files

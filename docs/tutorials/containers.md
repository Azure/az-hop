# Containers

## Support
Docker containers are supported via NVIDIA [enroot](https://github.com/NVIDIA/enroot) with [pyxis](https://github.com/NVIDIA/pyxis) plugin (SLURM only). Pyxis usage: [link](https://github.com/NVIDIA/pyxis#usage)

## Prerequisites
During deployment ([link](../deploy/define_environment.md)), make sure _enroot_enabled_ option is set to _true_ in **config.yml** in both sections:
 * **slurm** section
 * **queue** section for each queue which will run containers

## Examples
### Start an interactive job on Ubuntu
```bash
srun -N1 -p hc44rs --exclusive --container-image=ubuntu --pty bash
```

### Reusing a container within a job

#### Allocate a node
```bash
salloc -N1 -p hc44rs --exclusive
```

#### Run an interactive session in Ubuntu container from Docker Hub
```bash
srun --container-image=ubuntu --container-name=ubuntu_dev --pty bash
```
When `--container-name` option is specified, the container will not be automatically removed aftert the slurm task is complete.

#### Install any packages inside the container
```bash
apt-get update
apt-get install gcc make
```

#### Exit the session and reuse the container using its name for another bash session
```bash
exit
srun --container-name=ubuntu_dev --pty bash
gcc --version
exit
```

### Deploy NVIDIA pytorch container from NGC repository and start an interactive job
```bash
srun -p ndv4 -N 1 --exclusive --gpus-per-node=8 --container-image='nvcr.io#nvidia/pytorch:21.07-py3' --container-name=pytorch --pty bash
```

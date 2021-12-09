# OpenFOAM

## Prerequisites

These instructions build OpenFOAM with spack.  This assumes the installation has been setup as described [here](spack.md).

Build time is improved if a local disk is used. Check if your local `~/.spack/config.yaml` contains a *build_stage* entry for `/mnt/resource/$user/spack-stage` otherwise add it with the following command: 

```bash
sed '/^  build_stage:$/a \ \ \ \ - /mnt/resource/$user/spack-stage' $HOME/spack/etc/spack/defaults/config.yaml
```

## Start an interactive job on a compute node

```bash
qsub -l select=1:slot_type=hb120v2 -I
```

> Note: alternatively you could create a code-server session instead from the ondemand dashboard.


## Set up the spack environment

To set up your environment with Spack, run the following:

```
. ~/spack/share/spack/setup-env.sh
module use /usr/share/Modules/modulefiles
```

## Building OpenFOAM

This example will use OpenFOAM v8.  First install:

```bash
spack install openfoam-org@8
```

## Running the motorbike tutorial on a single node

The tutorials distributed with OpenFOAM should usually fit on a single node.  In the same session you can copy and run the motorbike tutorial.  First, load `openfoam-org` into the environment:

```bash
spack load openfoam-org@8
```

Copy the motorbike tutorial into scratch space:

```
mkdir -p /lustre/$USER
cd /lustre/$USER
cp -r $WM_PROJECT_DIR/tutorials/incompressible/simpleFoam/motorBike .
```

Run the tutorial:

```
cd motorBike
./Allrun
```

## Running multi node cases

This example with use a [DrivAer car](https://www.mw.tum.de/en/aer/research-groups/automotive/drivaer/) geometry and is available in the development branch of the OpenFOAM repository.  The instructions below will download the case and apply patches to run with OpenFOAM v8.

First, pull the latest development branch of OpenFOAM:

```
tmp_dir=/mnt/resource/$USER
mkdir -p $tmp_dir
pushd $tmp_dir
git clone https://github.com/OpenFOAM/OpenFOAM-dev.git
popd
```

Now copy the `drivaerFastback` tutorial:

```
scratch_dir=/lustre/$USER
mkdir $scratch_dir
cp -r $tmp_dir/OpenFOAM-dev/tutorials/incompressible/simpleFoam/drivaerFastback $scratch_dir/drivaerFastback
```

The following updates are needed:

* Add `FOAM_MPIRUN_FLAGS` to the `mpirun` command when using `runParallel` (needed for all version of OpenFOAM)
* Decompress the geometry
* Rename `constant/geometry` to 'constant/triSurface`
* Reconstruct the single partition after the solve

Below are the commands:

```
cd $scratch_dir/drivaerFastback
sed -i '/RunFunctions/a source <(declare -f runParallel | sed "s/mpirun/mpirun \\\$FOAM_MPIRUN_FLAGS/g")' Allrun
sed -i 's#/bin/sh#/bin/bash#g' Allrun
# decompress the geometry
gunzip constant/geometry/*
mv constant/geometry constant/triSurface
sed -i 's/# runApplication reconstructPar/runApplication reconstructPar/g' Allrun
```

Now, create a PBS submit script, `submit.sh`.  When running on multiple nodes it is necessary to export all the OpenFOAM environment variables (unless you add loading the modules in `.bashrc`).  This is done with the `FOAM_MPIRUN_FLAGS` that are added to the `runParallel` in the last step.  The script will run for the number of cores specified to PBS (`select` x `mpiprocs`):

```bash
#!/bin/bash
. ~/spack/share/spack/setup-env.sh
module use /usr/share/Modules/modulefiles
spack load openfoam-org
ranks_per_numa=4
export FOAM_MPIRUN_FLAGS="-hostfile $PBS_NODEFILE $(env |grep 'WM_\|FOAM' | cut -d'=' -f1 | sed 's/^/-x /g' | tr '\n' ' ') -x MPI_BUFFER_SIZE --report-bindings --map-by ppr:${ranks_per_numa}:numa"
$PBS_O_WORKDIR/Allrun -cores $(wc -l <$PBS_NODEFILE)
```

> Note: this assumes running 120 ranks per node - change the `ranks_per_numa` when running with fewer (e.g. ppn=60 -> ranks_per_numa=2, ppn=30 -> ranks_per_numa=1).

Submit the script:

```
nodes=8
ppn=120
qsub -l select=${nodes}:slot_type=hb120v2:ncpus=120:mpiprocs=${ppn},place=scatter:excl submit.sh
```

## Visualizing

ParaView can be used for vizualisation of OpenFOAM cases.  To install ParaView, download the installer from [here](https://www.paraview.org/download/).  The `tgz` installer can be used that only requires extracting.

Start a remote desktop session from the portal.  Navigate to the case directory and create a `case.foam` file:

```
touch case.foam
```

This is needed to enable ParaView to open the case.

Make sure you launch ParaView with `vglrun`, e.g.

```
cd /mnt/resource/$USER/drivaerFastback
touch case.foam
vglrun $HOME/ParaView-5.9.0-MPI-Linux-Python3.8-64bit/bin/paraview
```




## OPM
### Start a shell session
If not done, clone the azurehpc repo and use the azhop/spack branch
```bash
git clone https://github.com/Azure/azurehpc.git 
```

### Start an interactive job on a compute node
```bash
qsub -l select=1:slot_type=hpc -I
```

### Load Spack environment and modules
```bash
. ~/spack/share/spack/setup-env.sh
module use /usr/share/Modules/modulefiles
```

### Create the azhop spack repo
```bash
~/azurehpc/experimental/azhop/azhop-spack/install.sh
```

### Configure the OPM packages
```bash 
~/azurehpc/experimental/azhop/opm/configure.sh
```

### Build OPM => this can take 30+ minutes
```bash
~/azurehpc/experimental/azhop/opm/build.sh
```

### Get test data
```bash
cd /lustre
mkdir <user_alias>
cd <user_alias>
git clone https://github.com/OPM/opm-data.git
```

### Run a flow job
```bash
cp ~/azurehpc/experimental/azhop/opm/run_opm.sh .
```

### Change the input file path to /lustre/alias/… and select the number of nodes you want to run on (<4 as this is a small model)
### Submit your job and check for the result in the ~/OPM.* file
```bash
qsub ~/run_opm.sh 
qstat -fx <jobid>
pbsnodes -avS
```

### Start a Remote Desktop session and connect
ResInsight have been installed in the image but ideally, we want this to be done thru loading modules

### Start ResInsight
```bash
vglrun ResInsight
```

### In ResInsight import the eclipse case named NORNE_ATW2013.EGRID
This file is the output result of the OPM job and should be located in the /lustre/<alias>/opm-data/norne/out_parallel directory

## Installing SPACK

### Start a shell session, and clone the azurehpc repo and use the azhop/spack branch

```bash
git clone https://github.com/Azure/azurehpc.git 
```

### Start an interactive job on a compute node

```bash
qsub -l select=1:slot_type=hpc -I
```

### Wait the node to be provisioned (10 min)
In the interactive session, install and configure spack
```bash
~/azurehpc/experimental/azhop/spack/install.sh
~/azurehpc/experimental/azhop/spack/configure.sh
```

Confirm the list of compilers defined (gcc 9.2 should be listed)
```bash
. ~/spack/share/spack/setup-env.sh
spack compilers
```

# Configure the toolchain
The toolchain can be setup either locally or from a deployer VM. See below for instructions regarding the installation.

## From a local machine
### Clone the repo
It's important to clone the repo with its submodule. You can do this with one of these two options.

> Note : pick up the latest stable release from [https://github.com/Azure/az-hop/releases](https://github.com/Azure/az-hop/releases) and replace `<version>`

- Option 1
```bash
git clone --recursive https://github.com/Azure/az-hop.git -b <version>
```
 
- Option 2
```bash
git clone https://github.com/Azure/az-hop.git -b <version>
cd az-hop
git submodule init
git submodule update
```

### Set up the toolchain on Ubuntu 20.04 (e.g. WSL2)
For Terraform to work properly on  WSL2, on the C drive, make sure to have the "metadata mount" option enabled.
Afterwards, you can directly run the `install.sh`  script: 

```bash
sudo ./toolset/scripts/install.sh
```

## From a deployer VM
`az-hop` can be deployed directly from an Ubuntu 20.04 (prefered) or a CentOS 7.9 VM on Azure, preferably behind a Bastion.
In that case do the following :

- Create a Bastion
- Create a `deployer` VM running Ubuntu 20.04 without a public IP
- Connect to the `deployer` VM from Bastion
- Clone the repo as explained above
- Install the toolset by running 
  - For Ubuntu 20.04 : `sudo ./az-hop/toolset/scripts/install.sh`
  - For CentOS 7.9 : `sudo ./az-hop/toolset/scripts/install_centos.sh`

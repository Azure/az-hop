# DeployHPC, your deployment to be HPC-Ready! 

DeployHPC provides the end-2-end deployment mechanism for a base HPC infrastructure on Azure. Industry standard tools like Terraform, Ansible and Packer will be used.

## HPC Rover - Setup the toolchain

The `HPC Rover` is a docker container acting as a sandbox toolchain development environemnt to avoid impacting the local machine configuration. It is the same container if you are using Windows, Linux or macOS, you only need Visual Studio Code.

<img src="https://code.visualstudio.com/assets/docs/remote/containers/architecture-containers.png" width="75%">

You can learn more about the Visual Studio Code Remote on this [link](https://code.visualstudio.com/docs/remote/remote-overview).

### Pre-requisites

The Visual Studio Code system requirements describe the steps to follow to get your development environment ready -> [link](https://code.visualstudio.com/docs/remote/containers#_system-requirements)

* **Windows**: Docker Desktop 2.0+ on Windows 10 Pro/Enterprise with Linux Container mode
* **macOS**: Docker Desktop 2.0+
* **Linux**: Docker CE/EE 18.06+ and Docker Compose 1.24+

The `HPC Rover` is a Ubuntu 18.04 base image and is hosted on the Docker Hub [Link](https://hub.docker.com/r/xpillons/hpcrover/tags?page=1&ordering=last_updated)

Install
* Visual Studio Code version 1.41+ - [link](https://code.visualstudio.com/Download)
* Install Visual Studio Code Extension - Remote Development - [link](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

## Deploying

```
# Login to Azure
az login

# Use the deployhpc.tpl.yml as a template to create the deployhpc.yml file.

# Build the whole infrastructure
./build.sh -f ./tf -a apply

# install
./install.sh

# create a tunnel (outside of the container)
# The public IP of the jumbox canbe retrieved from the inventory file created
jb_ip=$(grep "hpcadmin@" playbooks/inventory | tail -n1 | cut -d'@' -f2 | cut -d'"' -f1)
ssh -L 9443:ccportal:9443 -i hpcadmin_id_rsa hpcadmin@$jb_ip

# Browse to the cycle UI
https://localhost:9443

# Connect with hpcadmin/<password generated>
grep "ad_join_password" playbooks/group_vars/all.yml  


#In the inventory file, locate the ondemand_fqdn variable, browse to this URI
#Connect with your user account and the password located in the inventory file
grep ondemand_fqdn playbooks/group_vars/all.yml  

# To access the grafana dashboard, browse to https://<ondemand_fqdn>/rnode/jumpbox/3000/

# From the OnDemand portal, select the menu "Clusters/_my_cluster Shell Access" to open a shell window
# Submit a simple test job 

```
qsub -l select=1:slot_type=hb60rs -- bash -c "sleep 60"
qstat

```

# Delete all
./build.sh -f ./tf -a destroy

```

## Persisting Terraform state in blobs
Terraform can persist it's deployment state into blobs. For this the storage account need to be created before running the `terraform init` command.
The `backend.sh` script will create a random storage account, and create the `./tf/backend.tf` file with all the values needed to keep the state there. The `build.sh` script will set the ARM_ACCESS_KEY used by Terraform to access the storage account.

Before running the `build.sh` script, run the `backend.sh` script.
```
./backend.sh
```

## Using Service Principal Name to build

Create a contributor SPN, give it a name you want
```
az ad sp create-for-rbac --name terraform_spn

# Keep the output safe as it contains a secret that will be displayed only once and needed later

# Assign the role "User Access Administrator" in order to create managed identity for CycleCloud

az role assignment create --assignee "http://terraform_spn" --role "User Access Administrator"


```
In order to use your SPN with packer to buid images you have to store it's secret in a keyvault and grant a read access policy to this 

> Note: You can also have a look on how to configure a [devops environment](./devops/readme.md).

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.




## Old documentation below => to be deleted



The installation steps consist of:
- prerequirements
Resource group, Virtual network etc.
- base infrastructure
Active Directory, CycleCloud, Scheduler, OpenOndemand and Home-storage 


## Pre-requisites

You need the following installed to launch:

* Terraform
* Ansible with the following collections:
  - community.windows
  - ansible.windows
  - ansible.posix
* Python3 with the following packages:
  - pypsrp
  - pysocks


## Setup on Ubuntu (e.g. WSL2)

```
# install terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# install ansible
sudo apt-get install ansible
# These are needed for AD
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows
# These are needed for OpenOnDemand
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general

# install python packages
sudo apt-get install python3-pip
pip3 install pypsrp
pip3 install pysocks
```



## TODO: Users

* Create home directory
* SSH config to StictHostKeyChecking false
* Create ssh key
* Copy public key to authorized keys



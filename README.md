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

# Update the configurations.tfvars file with your own values

# create infrastructure
# Initialize Terraform
terraform init ./tf

# Create a unique resource group name
UUID="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]' | cut -c 1-6)"
RESOURCE_GROUP="hpc_$UUID"

# Plan the deployment
terraform plan -var location=westeurope -var resource_group=$RESOURCE_GROUP ./tf

# Apply the deployment
terraform apply -auto-approve -var location=westeurope -var resource_group=$RESOURCE_GROUP ./tf

# install
ansible-playbook -i playbooks/inventory ./playbooks/ad.yml
ansible-playbook -i playbooks/inventory ./playbooks/linux.yml
ansible-playbook -i playbooks/inventory ./playbooks/ccportal.yml
ansible-playbook -i playbooks/inventory ./playbooks/scheduler.yml
ansible-playbook -i playbooks/inventory ./playbooks/ood.yml --extra-vars=@playbooks/ood-overrides.yml

# create a tunnel (outside of the container)
ssh -L 9443:ccportal:9443 -i hpcadmin_rsa_id hpcadmin@<public ip jumpbox>
# Browse to the cycle UI
https://localhost:9443


# Delete all
terraform destroy -auto-approve -var location=westeurope -var resource_group=$RESOURCE_GROUP ./tf

```

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
ansible-galaxy collection install ansible.windows
#ansible-galaxy collection install community.windows => this one seems no longer needed
ansible-galaxy collection install ansible.posix

# install python packages
sudo apt-get install python3-pip
pip3 install pypsrp
pip3 install pysocks
```





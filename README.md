# DeployHPC, your deployment to be HPC-Ready! 

DeployHPC provides the end-2-end deployment mechanism for a base HPC infrastructure on Azure. Industry standard tools like Terraform, Ansible and Packer will be used.

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
* Python3 with the following packages:
  - pypsrp
  - pysocks


## Installation on Ubuntu

```
# install terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# install ansible
sudo apt-get install ansible
ansible-galaxy collection install ansible.windows
ansible-galaxy collection install community.windows

# install python packages
sudo apt-get install python3-pip
pip3 install pypsrp
pip3 install pysocks

# clone the repo
git clone https://github.com/Azure/deployhpc.git
cd deployhpc

# create infrastructure
terraform init ./tf
terraform apply ./tf

# install
ansible-playbook -i playbooks/inventory ./playbooks/ad.yml
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

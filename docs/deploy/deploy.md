# Deploy your environment

## Build the infrastructure
Building the infrastructure is done thru the `build.sh` utility script, calling terraform. 
```bash
$ ./build.sh
Usage build.sh 
  Required arguments:
    -a|--action [plan, apply, destroy] 
   
  Optional arguments:
    -f|-folder <relative path> - relative folder name containing the terraform files, default is ./tf
```

Before deploying, make sure your are logged in to Azure.
The build script will use the `config.yml` file which will define the environment to be deployed.

```bash
# Login to Azure
az login

# Review the current subscription
az account show

# Change your default subscription if needed
az account set -s <subid>

# Build the whole infrastructure
./build.sh -f ./tf -a apply
```

At the end of the build, there are several files created, which produce the state of a deployment. These are :
 - az-hop config file `config.yml`
 - Terraform state file `tf/terraform.tfstate`
 - Ansible parameter files `playbooks/group_vars/all.yml`, `playbooks/inventory`
 - SSH Key Pair `${ADMIN_USER}_id_rsa` and `${ADMIN_USER}_id_rsa.pub`
 - Packer option file `packer/options.json`
 - Utility scripts `bin/*`


The URL to access the **azhop** web portal is in the inventory file, locate the **ondemand_fqdn** variable

```bash
grep ondemand_fqdn playbooks/group_vars/all.yml
```

State files can be uploaded to and downloaded from an existing azure storage account with the `azhop_state.sh` utility script. The files will be stored under a folder named with the resource group used to deploy the environment.

> Note : make sure that the storage account and the container exists.

```bash
$ ./azhop_state.sh 
azhop_state command account container resource_group
    command        = download, upload, delete
    account        = azure storage account to read/write state
    container      = container to use
    resource group = resource group to use (only for download)
```

Once the infrastructure is built you need to create the users.
## Create users passwords for all users defined in the config.yml file

Create users is done thru the `create_password.sh` utility script, which will use the `config.yml` file to retrieve the list of users to be created. For each, a password will be generated and stored as a secret in the keyvault built by the build command.

```bash
./create_passwords.sh
```

To retrieve a user's password from the key vault, use the `./bin/get_secret` utility script

```bash
./bin/get_secret hpcuser
```


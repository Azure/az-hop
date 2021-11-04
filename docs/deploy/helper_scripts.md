# Helper Scripts

- ansible_prereqs.sh
- azhop_states.sh
- build.sh
- create_passwords.sh
- install.sh
- packer/build_image.sh
- bin/connect
- bin/get_secret

## ansible_prereqs.sh
This script contains all the pre-reqs needed to run the **azhop** playbooks, and is called by the `install.sh` script.

## azhop_states.sh
This companion script allows you to upload/download all environment status files to/from blobs. Be aware that the Azure storage account and container should be created before running that script.

```bash
vscode@d0076264576c:/hpc$ ./azhop_state.sh 
azhop_state command account container resource_group
    command        = download, upload, delete
    account        = azure storage account to read/write state
    container      = container to use
    resource group = resource group to use (only for download)
vscode@d0076264576c:/hpc$
```

## build.sh
Script to build the resources needed for an **azhop** environment.

```bash
$ ./build.sh
Usage build.sh 
  Required arguments:
    -a|--action [plan, apply, destroy] 
   
  Optional arguments:
    -f|-folder <relative path> - relative folder name containing the terraform files, default is ./tf
```

At the end of the build, there are several files created, which produce the state of a deployment. These are :
 - az-hop config file `config.yml`
 - Terraform state file `tf/terraform.tfstate`
 - Ansible parameter files `playbooks/group_vars/all.yml`, `playbooks/inventory`
 - SSH Key Pair `${ADMIN_USER}_id_rsa` and `${ADMIN_USER}_id_rsa.pub`
 - Packer option file `packer/options.json`
 - Utility scripts `bin/*`

## create_passwords.sh
This script will create a random password per user defined in the `config.yml` file and store each in the keyvault under a secret named `<user>-password`
## install.sh
This script apply the applications configuration and settings on the **azhop** environment for all of these targets :
- ad
- linux
- add_users
- lustre
- ccportal
- cccluster
- scheduler
- ood
- grafana 
- telegraf
- chrony

The simpler is just to run 
```bash
./install.sh
```
and let it go

If you need to apply only a subset then run 
```bash
./install.sh <target> # with a single target in the list above
```

In case of a transient failure, the install script can be reapplied as most of the settings are idempotent.

## packer/build_image.sh
Script to build images defined the the `config.yml` file and in the `packer/<image_file.json>` packer files.

```bash
vscode@d0076264576c:/hpc/packer$ ./build_image.sh 
Usage build_image.sh 
  Required arguments:
    -i|--image <image_file.json> | image packer file
   
  Optional arguments:
    -o|--options <options.json>  | file with options for packer generated in the build phase
    -f|--force                   | overwrite existing image and always push a new version in the SIG
```

The `build_image.sh` script will :
- build a managed image with packer, 
- tag this image with the checksum of the scripts called to build that image, 
- tag it with a version, 
- create the image definition in the Shared Image Gallery if it doesn't exists
- push the managed image in the Shared Image Gallery

Please read the [Build Images](build_images.md) documentation for more details.

## bin/connect 
The `bin/connect` command will be created by terraform in the build phase.  In addition to the specific `cyclecloud` and `ad` commands it can be a general wrapper for `ssh` in order to access resources on the vnet. This will handle proxy-ing through the **jumpbox** and so you can connect directly to the resources on the vnet.  For example, to connect to the ondemand, you can run the following:

```bash
./bin/connect hpcadmin@ondemand
```

## bin/get_secret
This utility command will retrieve a user password stored in the keyvault created during the build phase.

```bash
./bin/get_secret <username>
```


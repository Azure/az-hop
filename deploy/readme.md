# AZ-HOP: Marketplace deployment

## Pre-requisites

- pwgen
- updated yq version
- az bicep install
- az extension add --name ssh

## Generating the template

All resources are deployed in a single template.  A deployer VM is created with a customData script to perform the install process.  Set the new `build.yaml` and run the following to generate the template:

`build.py > azhop.bicep`
    
This will create the bicep template.  This uses the new `build.yaml` as an input parameter and concatonates the endered jinja2 templates:
- parameters.bicep.j2
- nsg.bicep.j2
- network.bicep.j2
- asg.bicep.j2
- vms.bicep.j2
- anf.bicep.j2
- sig.bicep.j2
- keyvault.bicep.j2
- secrets.bicep.j2
- storage.bicep.j2
- mysql.bicep.j2
- bastion.bicep.j2
- outputs.bicep.j2
- vpngateway.bicep.j2

This file would need to be converted to ARM in order to publish in the marketplace.  The bicep script itself will embed the `deploy.sh` and the `build.yml`.

> Note: the `build.yml` should not be changed between calling `build.py` and deploying.

## Installation


## AD notes

# list users
ldapsearch -v -x -D "hpcadmin@hpc.azure" -W -b "DC=hpc,DC=azure" -H "ldap://ad" "(&(objectClass=user))"
# list groups
ldapsearch -v -x -D "hpcadmin@hpc.azure" -W -b "DC=hpc,DC=azure" -H "ldap://ad" "(&(objectClass=group))"


## Terraform


## Ansible

This step needs to be updated to separate package installs and configuration setup.  This currently relies on the `build.yml`.  All usage of this file should be removed.

Below are the playbooks to be update.

- [ ] ad
- [ ] linux
- [ ] lustre-sas
- [ ] lustre
- [ ] ccportal
- [ ] add_users
- [ ] cccluster
- [ ] scheduler
- [ ] ood-overrides-common.yml 
- [ ] ood-overrides-$SCHEDULER.yml
- [ ] ood-overrides-auth-$OOD_AUTH.yml
- [ ] $ENABLE_WINVIZ_PLAYBOOK
- [ ] ood-custom
- [ ] guacamole
- [ ] guac_spooler
- [ ] grafana 
- [ ] telegraf
- [ ] chrony

Todo:

- [ ] dual protocol support for ANF (deploy ANF as a second step once AD is configured)
- [ ] remove need to store the ad password in the ansible inventory
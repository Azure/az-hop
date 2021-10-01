# Installation
Once the whole infrastrtucture has been deployed you need to install and configure the softwares. To do so the `install.sh` utility script is used.

## Install and configure the deployed environment
The installation is done with Ansible playbooks and can be applied as a whole or by components, but there is an order to follow as playbooks have dependencies :
- ad
- linux
- add_users
- lustre
- ccportal
- ccpbs
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
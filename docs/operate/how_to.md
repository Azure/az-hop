# How To

## How to add new node type/configuration ?
Edit the `config.yml` configuration file to add new queues definitions. Then apply the new configuration to Cycle by running :
```bash
./install.sh ccpbs
```

## How to refresh the SSL certificate ?
By default the SSL certificate has a 90 days expiration. To refresh the certificate follow the steps above. Please make sure that the website is not used before running these steps.

### Connect on the ondemand VM
Delete certificate and configuration files 
```bash
./bin/connect hpcadmin@ondemand
sudo su -
rm -rf .getssl/
rm -rf /etc/ssl/*.cloudapp.azure.com/
rm -f /opt/rh/httpd24/root/etc/httpd/conf.d/ood-portal.conf
rm -rf /var/www/ood/.well-known
```

### Rerun the OOD playbook
```bash
install.sh ood
```

> Note: In case of failure when applying the playbook, redo these steps.

## How to Add/remove/modify cluster node arrays (aka queues/partitions) ?
Az-HOP simplifies the addition, removal or modification of the node arrays in an existing CycleCloud cluster.
Simply edit the `config.yml` file with the desired changes in the `queues` section. Then rerun the playbooks `cccluster` and `scheduler` (only for SLURM) installation with:
```bash
./install cccluster
./install scheduler
```
The node arrays changes will appear in the CycleCloud portal and as cluster scheduler partitions.

## How to add your own custom init scripts to run on node startup ?
CycleCloud will run init scripts at node startup used to configure the node with the `az-hop` components like job scheduler configuration, monitoring or healthchecks. You can add your own scripts which will be called after the `az-hop` ones.

Use this file `./playbooks/roles/cyclecloud_cluster/projects/common/cluster-init/scripts/zz-custom.sh` to add your customizations but don't rename it.

Then rerun the playbooks `cccluster` and `scheduler` (only for SLURM) installation with:
```bash
./install cccluster
./install scheduler
```

## How to add your own custom init scripts when building images ?
There are two placeholder scripts named `zz-compute-custom.sh` and `zz-desktop-custom.sh` respectively for extending the compute nodes and remote desktop nodes image configuration. These scripts are in each OS section in the `./packer/scripts/<os>/` directory.
Just update the related custom scripts with your content before building the image.

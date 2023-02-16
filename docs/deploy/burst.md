# Cloud Bursting

## Introduction to federation
Az-hop can be configured to burst HPC workloads to Azure using [Slurm federation](https://slurm.schedmd.com/federation.html). Slurm offers the ability to target commands to other clusters which is called `multi-cluster`. When this behavior is enabled, users can submit jobs to one or many clusters and receive status from those remote clusters. Slurm also includes support for creating a `federation` of clusters and scheduling jobs in a peer-to-peer fashion between them. Jobs submitted to a federation receive a unique job ID that is unique among all clusters in the federation. Federation is a superset of multi-cluster. By setting up federation, you are also setting up multi-cluster.

## Prerequisites
* Connectivity between Slurm controller and slurmdbd nodes on the on-premises cluster and the controller node on the Azure cluster on ports 6817 and 6819.
* Consistent user IDs across all clusters in the federation
* Slurm accounting set up on the on-premises cluster
* Munge keys must match for Slurm communications to work
* Optional shared file system for shared data between clusters
* If `az-hop` is already deployed, you will need to remove the munge key and regenerate `slurm.conf` on the scheduler node
  * `sudo rm /sched/munge/munge.key`
  * Back up /etc/slurm/slurm.conf if there are any customizations
  * `sudo rm /etc/slurm/slurm.conf`


## Configuration
### Add the following setting to the `config.yml` file in the `slurm` section:

```yaml
slurm:
  multi_cluster:
    slurmdbd: 10.10.10.10 # IP address of the primary slurmdbd server to connect to
```

### Add the munge key from the on-prem cluster into the key vault
The key vault name is stored in `playbooks/group_vars/all.yml` on the deployer machine
```bash
# read the key vault name
grep key_vault playbooks/group_vars/all.yml

# add the munge key to the key vault (replace <keyvault_name> with the key vault name)
# use --value instead of --file to specify the munge key on the command line
# (make sure the key is identical, including newlines or any whitespace)
az keyvault secret set --vault-name <keyvault_name> --name munge-key --file onprem-munge.key
```
### Make sure cluster names are unique
Cluster name can be set in the slurm section of config.yml:
```yaml
slurm:
  cluster_name: cloud_burst
  multi_cluster:
    slurmdbd: 10.10.10.10 # IP address of the primary slurmdbd server to connect to
```

### Create NSG rules to allow traffic to/from the on-premises cluster
If the `multi_cluster` setting exists before the cluster is deployed, the NSG rules will be created automatically (bicep deployment only). If the setting is added after the cluster is deployed, the NSG rules will need to be created manually. The NSG name is `nsg-common`, the traffic has to be allowed in both directions between `asg-pbs` application security group and the on-premises `slurmctld` and `slurmdbd` nodes on ports `6817` and `6819`.

### Run the scheduler playbook
```bash
./install.sh scheduler
```

### Check if the clusters are connected
Use `sacctmgr list cluster` command to verify that all clusters are listed with their correct ControlHost IP addresses.
```bash
[root@scheduler ~]# sacctmgr list cluster format=cluster%16,controlhost,controlport
         Cluster     ControlHost  ControlPort
---------------- --------------- ------------
     cloud_azhop     10.179.0.20         6817
         on-prem     10.115.0.20         6817
```

### Add federation if required
```bash
sacctmgr add federation name=cloudburst clusters=cloud_burst,on-prem
```
Check the federation status:
```bash
[hpcadmin@scheduler ~]$ sacctmgr list fed
Federation    Cluster ID             Features     FedState
---------- ---------- -- -------------------- ------------
burst_azh+ cloud_azh+  2                            ACTIVE
burst_azh+    on-prem  1                            ACTIVE
```


## Troubleshooting
### Errors during the deployment
If the name of the cluster has been changed after the initial deployment, slurmctld will fail to start when running the `scheduler` playbok. The error message will look like this:
```bash
[2023-02-09T16:33:56.054] fatal: CLUSTER NAME MISMATCH.
slurmctld has been started with "ClusterName=on-prem", but read "slurm" from the state files in StateSaveLocation.
Running multiple clusters from a shared StateSaveLocation WILL CAUSE CORRUPTION.
Remove /var/spool/slurmd/clustername to override this safety check if this is intentional (e.g., the ClusterName has changed).
```
To fix this, make sure the cluster is quiet and remove the file `/var/spool/slurmd/clustername` on the scheduler node. Then re-run the scheduler playbook.

If the munge key is not the same on the scheduler node and the on-premises cluster, the following error will be logged in `/var/log/slurmctld/slurmctld.log`:
```bash
[2021-02-09T16:33:58.132] error: slurmctld: slurm_receive_msg: Connection reset by peer
```
* Make sure there are no compute nodes in the cluster
* Remove the file `/sched/munge/munge.key` on the scheduler node
* Check that the munge key is stored in teh key vault. If it is not, add it using the instructions above.
* Re-run the scheduler playbook.

If slurmctld fails to start unable to contact slurmdbd, check the network connectivity between the scheduler node and the slutmctld and slurmdbd on the on-premises cluster.

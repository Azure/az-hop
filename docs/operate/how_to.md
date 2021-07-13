# How To

## How to add new node type/configuration ?
Edit the `config.yml` configuration file to add new queues definitions. Then apply the new configuration to Cycle by running :
```bash
./install.sh ccpbs
```

## How to provide sudo access on nodes ?
Edit the file `playbooks/roles/cyclecloud_pbs/cluster-init/scripts/6-default.sh` and uncomment the line that grant sudo to domain users
```
# Grant domain users sudo with no password
echo "\"%domain users\" ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
```
Then apply the new configuration to Cycle by running :
```bash
./install.sh ccpbs
```
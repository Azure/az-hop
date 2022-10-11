# Node Health Check
Compute node health checks are implemented using [LBNL NHC](https://github.com/mej/nhc) framework. NHC runs a series of quick tests to verify that the node is working properly. When the node is found to be "unhealthy", the error message is logged in the CycleCloud GUI and the node is shut down. Actual set of tests depends on the VM type.

## Invocation
If the cluster is configured with PBS queue manager, NHC will be automatically run on node creation.

If the cluster is configured with SLURM, NHC will run:
- on node creation
- in job epilog (after job completion)
- periodically on any node in the IDLE state (not running jobs)

NHC is implemented in `bash` and can be extended with custom scripts. Different checks can be run depending on the type of the Azure VM.

## Common Checks 
The following checks are performed on all VMs regardless of the type:
- hostname is correct
- node is domain joined
- filesystems are not full
- Lustre is mounted (if Lustre is configured in config.yml)
- SLURM share is mounted (SLURM only)
- sshd and telegraf services are running

## VM specific checks
### All HBv2, HBv3, HC:
- Infiniband is configured and running at full speed

### All NV (except NVv4), NC, ND:
- nvidia-smi health monitor

### ND96asr_v4:
- all 8 Mellanox HDR cards are running at 200 Gb/s
- all 8 GPUs checked for:
    * Persistence mode enabled (if not, attempt to enable and fail only if unable to fix)
    * GPU clocks speed is set to max (if not, it attempts to fix and fail only if unable)
    * Throttling
    * Row remap errors
    * Xid errors in dmesg

## Adding custom tests to NHC
Configuration files related to HNC are located in `playbooks/roles/cyclecloud_cluster/common/cluster-init/files/nhc`

|File|Description|
|----|-----------|
|`nhc_common.conf.j2`  |Configuration file with the common checks (to be run on *all* nodes)|
|`nhc_nd96asr_v4.conf` |Additional tests for ND96asr_v4|
|`nhc_hb120rs_v3.conf` |Additional tests for HB120rs_v3|
|`nhc_`*vm_type*`.conf`|Additional tests for any VM type (lowercase)|
|`scripts/`|Directory with custom scripts (bash)|

# References
LBNL NHC documentation: https://github.com/mej/nhc#table-of-contents-by-gh-md-toc

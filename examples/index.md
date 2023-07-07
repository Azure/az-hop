# Configuration Examples
This folder contains examples of pre-defined configuration files for common scenarios as described below.


| Config file name         | Public IP | Storage | VNET/Subnet | Azure Monitor | Alerting | Lustre | Slurm Accounting |
|--------------------------|-----------|---------|-------------|---------------|----------|--------|------------------|
| minimum_public_ip.yml    | Yes       | ANF     | Create      | No            | No       | No     | No               |
| qinstall-config.yml    | Yes       | ANF     | Create      | No            | No       | No     | No               |

## minimum_public_ip.yml
This configuration file is defining the minimum required to build an `azhop` environment when public IP is allowed.

## qinstall-config.yml
This configuration file is defining the minimum required to quickly deploy `azhop` environment. You can follow the guide [HERE](https://azure.github.io/az-hop/tutorials/quick_install.html).
# Azure HPC On-Demand Platform, your deployment to be HPC-Ready! 

Azure HPC On-Demand Platform (az-hop), provides the end-to-end deployment mechanism for a base HPC infrastructure on Azure. az-hop delivers a complete HPC cluster solution ready for users to run applications, which is easy to deploy and manage for HPC administrators. az-hop leverages the various Azure building blocks and can be used as-is, or easily customized and extended to meet any uncovered requirements. Industry standard tools like Terraform, Ansible and Packer are used to provision and configure this environment containing :
- An [HPC OnDemand Portal](https://osc.github.io/ood-documentation) for all user access, remote shell access, remote visualization access, job submission, file access and more,
- An Active Directory for user authentication and domain control,
- [Open PBS](https://openpbs.org/) or [SLURM](https://slurm.schedmd.com/overview.html) as a Job Scheduler,
- Dynamic resources provisioning and autoscaling is done by [Azure CycleCloud](https://docs.microsoft.com/en-us/azure/cyclecloud/?view=cyclecloud-8) pre-configured job queues and integrated health-checks to quickly avoid non-optimal nodes,
- A Jumpbox to provide admin access,
- A common shared file system for home directory and applications is delivered by [Azure Netapp Files](https://azure.microsoft.com/en-us/services/netapp/),
- A Lustre parallel filesystem using local NVME for high performance that automatically archives to [Azure Blob Storage](https://azure.microsoft.com/en-gb/services/storage/blobs/) using the [Robinhood Policy Engine](https://github.com/cea-hpc/robinhood) and [Azure Storage data mover](https://github.com/wastore/lemur),
- [Grafana](https://grafana.com/) dashboards to monitor your cluster,
- Remote Visualization with [noVNC](https://novnc.com/info.html) and GPU acceleration with [VirtualGL](https://www.virtualgl.org/).

Please check the whole **azhop** [documentation here](https://azure.github.io/az-hop/).

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


# Azure HPC On-Demand Platform, your deployment to be HPC-Ready! 

Azure HPC On-Demand Platform, provides the end-2-end deployment mechanism for a base HPC infrastructure on Azure. Industry standard tools like Terraform, Ansible and Packer are used to provision and configure this environment containing :
- An OpenOn Demand Portal for all user access, remote shell access, remote visualization access, job submission, file access and more,
- An Active Directory for user authentication and domain control,
- Open PBS as a Job Scheduler,
- Cycle Cloud 8.1 to handle autoscaling of PBS Nodes thru the scalelib integration,
- A Jumpbox to provide admin access,
- Azure Netapp Files for home directory and data storage,
- A Lustre cluster as a parallel file system,
- Grafana dashboards to monitor your cluster

Please check the whole **azhop** [documentation here]().

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


<!-- TOC -->

- [Azure HPC OnDemand Platform lab guide](#azure-hpc-on-demand-platform-lab-guide)
  - [Requirements](#requirements)
  - [Before the hands-on lab](#before-the-hands-on-lab)
    - [Task 1: Validate the owner role assignment in the Azure subscription](#task-1-validate-the-owner-role-assignment-in-the-azure-subscription)
    - [Task 2: Validate a sufficient number of vCPU cores](#task-2-validate-a-sufficient-number-of-vcpu-cores)
  - [Exercise 1: Prepare for implementing Azure HPC OnDemand Platform environment](#exercise-1-prepare-for-implementing-azure-hpc-ondemand-platform-environment)
    - [Task 1: Provision an Azure VM running Linux](#task-1-provision-an-azure-vm-running-linux)
    - [Task 2: Deploy Azure Bastion](#task-2-deploy-azure-bastion)
    - [Task 3: Install the az-hop toolset](#task-3-install-the-az-hop-toolset)
    - [Task 4: Prepare the Azure subscription for deployment](#task-4-prepare-the-azure-subscription-for-deployment)
  - [Exercise 2: Implement Azure HPC OnDemand Platform infrastructure](#exercise-2-implement-azure-hpc-ondemand-platform-infrastructure)
    - [Task 1: Customize infrastructure components](#task-1-customize-infrastructure-components)
    - [Task 2: Deploy Azure HPC OnDemand Platform cloud infrastructure](#task-2-deploy-azure-hpc-ondemand-platform-cloud-infrastructure)
    - [Task 3: Build images](#task-3-build-images)
    - [Task 4: Review deployment results](#task-4-review-deployment-results)
    - [Task 5: Generate passwords for user and admin accounts](#task-5-generate-passwords-for-user-and-admin-accounts)
  - [Exercise 3: Install and configure Azure HPC OnDemand Platform software components](#exercise-3-install-and-configure-azure-hpc-ondemand-platform-software-components)
    - [Task 1: Install Azure HPC OnDemand Platform software components](#task-1-install-azure-hpc-ondemand-platform-software-components)
    - [Task 2: Review installation results](#task-2-review-installation-results)
  - [Exercise 4: Review the main az-hop features](#exercise-4-review-the-main-az-hop-features)
    - [Task 1: Using file explorer](#task-1-using-file-explorer)
    - [Task 2: Using shell access](#task-2-using-shell-access)
    - [Task 3: Running interactive apps using Code Server and Remote Desktop](#task-3-running-interactive-apps-using-code-server-and-remote-desktop)
    - [Task 4: Running Intel MPI PingPong jobs from the Job composer](#task-4-running-intel-mpi-pingpong-jobs-from-the-job-composer)
    - [Task 5: Create jobs based on a non-default Azure HPC OnDemand Platform template](#task-5-create-jobs-based-on-a-non-default-azure-hpc-ondemand-platform-template)
  - [Exercise 5: Set up Spack](#exercise-5-set-up-spack)
    - [Task 1: Create a compute node](#task-1-create-a-compute-node)
    - [Task 2: Install Spack](#task-2-install-spack)
  - [Exercise 6: Build, run, and analyze reservoir simulation using OPM Flow](#exercise-6-build-run-and-analyze-reservoir-simulation-using-opm-flow)
    - [Task 1: Build OPM](#task-1-build-opm)
    - [Task 2: Retrieve test data and run a flow job](#task-2-retrieve-test-data-and-run-a-flow-job)
    - [Task 3: View the results of the OPM job by using ResInsight](#task-3-view-the-results-of-the-opm-job-by-using-resinsight)
  - [Exercise 7: Deprovision Azure HPC OnDemand Platform environment](#exercise-7-deprovision-azure-hpc-ondemand-platform-environment)
    - [Task 1: Terminate the cluster](#task-1-terminate-the-cluster)
    - [Task 2: Deprovision the Azure resources](#task-2-deprovision-the-azure-resources)

<!-- /TOC -->

# Azure HPC OnDemand Platform lab guide

## Requirements

- A Microsoft Azure subscription
- A work or school account with the Owner role in the Azure subscription
- A lab computer with:

  - Access to Azure
  - A web browser supported by the Azure portal (Microsoft Edge, Google Chrome, or Mozilla Firefox)

## Before the hands-on lab

Duration: 15 minutes

To complete this lab, you must verify that your account has sufficient permissions to the Azure subscription that you intend to use to deploy all required Azure resources. The Azure subscription must have a sufficient number of available vCPUs.

### Task 1: Validate the owner role assignment in the Azure subscription

1. From the lab computer, start a web browser, navigate to [the Azure portal](http://portal.azure.com), and if needed, sign in with the credentials of the user account with the Owner role in the Azure subscription you will be using in this lab.
1. In the Azure portal, use the **Search resources, services, and docs** text box to search for **Subscriptions**, and in the list of results, select **Subscriptions**.
1. On the **Subscriptions** blade, select the name of the subscription you intend to use for this lab.
1. On the subscription blade, select **Access control (IAM)**.
1. On the **Check access** tab, select the **View my access** button, and in the listing of role assignments, verify that your user account has the Owner role assigned to it.

### Task 2: Validate a sufficient number of vCPU cores

1. In the Azure portal, on the subscription blade, in the **Settings** section of the resource menu, select **Usage + quota**.
1. On the **Usage + quotas** blade, in the **Search** filters drop-down boxes, select the Azure region you intend to use for this lab and the **Microsoft.Compute** provider entry.

   > ![Note]: We recommend that you use the **South Central US** or the **West Europe** regions because these currently are more likely to increase the possibility of successfully raising quota limits for the Azure virtual machine (VM) SKUs required for this lab.

1. Review the listing of existing quotas and determine whether you have sufficient capacity to accommodate a deployment of the following vCPUs:

   - Standard BS Family vCPUs: **12**
   - Standard DDv4 Family vCPUs: **80**
   - Standard DSv3 Family vCPUs: **16** <!-- increased from 8 - required for the centos-7.8-desktop-3d image build -->
   - Standard DSv5 Family vCPUs: **4**
   - Standard HBrsv2 Family vCPUs: **480**
   - Standard HBv3 Family vCPUs: **480**
   - Standard NV Family vCPUs: **6**
   - Total Regional Spot vCPUs: **960**
   - Total Regional vCPUs: **590**

1. If the number of vCPUs isn't sufficient, on the subscription's **Usage + quotas** blade, select **Request Increase**.
1. On the **Basic** tab of the **New support request** blade, specify the following, and then select **Next: Solutions >**:

   - Summary: **Insufficient compute quotas**
   - Issue type: **Service and subscription limits (quotas)**
   - Subscription: Enter the name of the Azure subscription you will be using in this lab.
   - Quota type: **Compute-VM (cores-vCPUs) subscription limit increases**
   - Support plan: Enter the name of the support plan associated with the target subscription.

1. On the **Details** tab of the **New support request** blade, select the **Enter details** link.
1. On the **Quota details** tab of the **New support request** blade, specify the following settings, and then select **Save and continue**:

   - Deployment model: **Resource Manager**
   - Location: Enter the name of the target Azure region you intend to use in this lab.
   - Quotas: Enter the VM series and the new vCPU limit.

1. On the **Details** tab of the **New support request** blade, specify the following settings, and then select **Next: Review + create >**:

   - Advanced diagnostic information: **Yes**
   - Severity: **C - Minimal impact**
   - Preferred contact method: Choose your preferred option and provide your contact details.

1. On the **Review + create** tab of the **New support request** blade, select **Create**.

   > ![Note]: Typically, requests for quota increases are completed within a few hours, but its possible that the processing might take up to a few days.

## Exercise 1: Prepare for implementing the Azure HPC OnDemand Platform environment

Duration: 40 minutes

In this exercise, you will set up an Azure VM that you will use for deployment of the lab environment.

### Task 1: Provision an Azure VM running Linux

1. From the lab computer, start a web browser, navigate to [the Azure portal](http://portal.azure.com), and if needed, sign in with credentials of the account with the Owner role in the Azure subscription you will be using in this lab.
1. In the Azure portal, start a Bash session in **Cloud Shell**.

   > ![Note]: If prompted, in the **Welcome to Azure Cloud Shell** window, select **Bash (Linux)**, and in the **You have no storage mounted** window, select **Create storage**.

1. In the **Bash** session, in the **Cloud Shell** pane, run the following command to select the Azure subscription in which you will provision the Azure resources in this lab. In the following command, replace the `<subscription_ID>` placeholder with the value of the **subscriptionID** property of the Azure subscription you are using in this lab:

   > ![Note]: To list the subscription ID properties of all subscriptions associated with your account, run `az account list -otable --query '[].{subscriptionId: id, name: name, isDefault: isDefault}'`.

   ```bash
   az account set --subscription '<subscription_ID>'
   ```

1. Run the following commands to create an Azure resource group that will contain the Azure VM hosting the lab deployment tools. In the following commands, replace the `<Azure_region>` placeholder with the name of the Azure region you intend to use in this lab:

   > ![Note]: You can use the `az account list-locations -o table` command to list the names of Azure regions available in your Azure subscription:

   ```bash
   LOCATION='<Azure_region>'
   RGNAME='azhop-cli-RG'
   az group create --location $LOCATION --name $RGNAME
   ```

1. Run the following commands to download the Azure Resource Manager template and the corresponding parameters file into the Cloud Shell home directory. You will use the template and file to provision the Azure VM that will host the lab deployment tools:

   ```bash
   rm ubuntu_azurecli_vm_template.json -f
   rm ubuntu_azurecli_vm_template.parameters.json -f

   wget https://raw.githubusercontent.com/polichtm/az-hop/main/templates/ubuntu_azurecli_vm_template.json
   wget https://raw.githubusercontent.com/polichtm/az-hop/main/templates/ubuntu_azurecli_vm_template.parameters.json
   ```

1. Run the following command to provision the Azure VM that will host the lab deployment tools:

   ```bash
   az deployment group create \
   --resource-group $RGNAME \
   --template-file ubuntu_azurecli_vm_template.json \
   --parameters @ubuntu_azurecli_vm_template.parameters.json
   ```

   > ![Note]: When prompted, enter an arbitrary password that will be assigned to the **azureadm** user, which you will use to sign in to the operating system of the Azure VM.

   > ![Note]: Wait until the provisioning completes. This should take about 3 minutes.

### Task 2: Deploy Azure Bastion

> ![Note]: Azure Bastion allows users to connect to Azure VMs without relying on public endpoints and helps provide protection against brute force exploits that target operating system level credentials.

1. On the lab computer, in the browser window displaying the Azure portal, from the Bash session in the **Cloud Shell** pane, run the following commands to add a subnet named **AzureBastionSubnet** to the virtual network that you created in the previous task:

   ```bash
   RGNAME='azhop-cli-RG'
   VNETNAME='azcli-vnet'
   az network vnet subnet create --resource-group $RGNAME --vnet-name $VNETNAME --name AzureBastionSubnet --address-prefixes 192.168.3.0/24
   ```

1. Close the **Cloud Shell** pane.
1. In the Azure portal, use the **Search resources, services, and docs** text box to search for **Bastions**, and in the list of results, select **Bastions**.
1. On the **Bastions** blade, select **+ Create**.
1. On the **Basic** tab of the **Create a Bastion** blade, specify the following settings, and then select **Review + create**:

   |Setting|Value|
   |---|---|
   |Subscription|Enter the name of the Azure subscription you are using in this lab.|
   |Resource group|**azhop-cli-RG**|
   |Name|**azhop-cli-bastion**|
   |Region|Enter the same Azure region to which you used for deployment in the previous task of this exercise.|
   |Tier|**Basic**|
   |Virtual network|**azcli-vnet**|
   |Subnet|**AzureBastionSubnet (192.168.3.0/24)**|
   |Public IP address|**Create new**|
   |Public IP name|**azhop-cli-pip**|

1. On the **Review + create** tab of the **Create a Bastion** blade, select **Create**.

   > ![Note]: Wait for the deployment to complete before you proceed to the next exercise. The deployment might take about 5 minutes to complete.

### Task 3: Install the az-hop toolset

> ![Note]: Ensure that your browser has the pop-up functionality enabled before you attempt to connect through Azure Bastion.

1. On the lab computer, in the browser window displaying the Azure portal, use the **Search resources, services, and docs** text box to search for **Virtual machines**, and from the **Virtual machines** blade, select **azcli-vm0**.
1. On the **azcli-vm0** blade, select **Connect**, from the drop-down menu, select **Bastion**, on the **azcli-vm0 \| Bastion** blade, enter **azureadm** as the user name and the password you set during the Azure VM deployment in the first task of this exercise, and then select **Connect**.
1. Within the SSH session to the Azure VM, run the following command to update the package manager list of available packages and their versions:

   ```bash
   sudo apt-get update
   ```

1. Run the following command to upgrade the versions of the local packages and confirm when prompted whether to proceed:

   ```bash
   sudo apt-get upgrade -y
   ```

1. Run the following command to install Git:

   ```bash
   sudo apt-get install git
   ```

1. Run the following commands to clone the **az-hop** repository:

   ```bash
   rm ~/az-hop -rf
   git clone --recursive https://github.com/Azure/az-hop.git -b v1.0.14
   ```

1. Run the following commands to install all the tools required to provision the **az-hop** environment:

   ```bash
   cd ~/az-hop/
   sudo ./toolset/scripts/install.sh
   ```

   > ![Note]: Wait until the script completes running. This might take about 5 minutes.

### Task 4: Prepare the Azure subscription for deployment

1. Within the SSH session to the Azure VM, run the following command to sign in to the Azure subscription you are using in this lab:

   ```bash
   az login
   ```

1. Note the code displayed in the output of the command. Switch to your lab computer, open another tab in the browser window displaying the Azure portal, navigate to [the Microsoft Device Login page](https://microsoft.com/devicelogin), enter the code, and then select **Next**.
1. If prompted, sign in with the credentials of the user account with the Owner role in the Azure subscription you are using in this lab,  select **Continue**, and then close the newly opened browser tab.
1. In the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following command to identify the Azure subscription you are connected to:

   ```bash
   az account show
   ```

1. If the Azure subscription you are connected to is different from the one you intend to use in this lab, run the following command to change the subscription to which you are currently connected. In the following command, replace the `<subscription_ID>` placeholder with the value of the subscriptionID parameter of the Azure subscription you intend to use in this lab:

   ```bash
   az account set --subscription '<subscription_ID>'
   ```

1. Within the SSH session to the Azure VM, run the following command to ensure that the CycleCloud marketplace image is available in your Azure subscription:

   ```bash
   az vm image terms accept --offer azure-cyclecloud --publisher azurecyclecloud --plan cyclecloud-81
   ```

1. Run the following command to ensure that the Azure HPC Lustre marketplace image is available in your Azure subscription:

   ```bash
   az vm image terms accept --offer azurehpc-lustre --publisher azhpc --plan azurehpc-lustre-2_12
   ```

1. Run the following command to register the Azure NetApp Resource Provider:

   ```bash
   az provider register --namespace Microsoft.NetApp --wait
   ```

1. Run the following command to verify that the Azure Resource Provider has been registered:

   ```bash
   az provider list --query "[?namespace=='Microsoft.NetApp']" --output table
   ```

   > ![Note]: In the output of the command, verify that the value of **RegistrationState** is listed as **Registered**.

## Exercise 2: Implement Azure HPC OnDemand Platform cloud infrastructure

Duration: 90 minutes

In this exercise, you will deploy the Azure HPC OnDemand Platform infrastructure.

### Task 1: Customize infrastructure components

You can define an az-hop environment by using a configuration file named **config.yml**, which needs to reside in the root of the repository. The simplest way to create the environment is to clone the template file **config.tpl.yml** and modify the content of the copied file. In this task, you will review its content and if needed, set the target Azure region for deploying the Azure HPC OnDemand Platform infrastructure.

1. On the lab computer, in the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following commands to copy **config.tpl.yml** to **config.yml**:

   ```bash
   cp config.tpl.yml config.yml
   ```

1. Open the **config.yml** file using your preferred editor such as Nano or vi:

   ```bash
   vi config.yml
   ```

1. Review the content of the **config.yml** file and note that it includes the following settings:

   - **location**: The name of the target Azure region.
   - **resource_group**: The name of the target resource group. You do have the option of using an existing resource group by setting **use_existing_rg** to **true**.
   - **anf**: Configuration properties of Azure NetApp Files resources.
   - **admin_user**: The name of the admin user account. Its random password is autogenerated and stored in the Azure Key vault provisioned as part of the deployment.
   - **network**: Configuration properties of the Azure virtual network into which the Azure resources hosting the infrastructure resources are deployed.
   - **jumpbox**, **ad**, **ondemand**, **grafana**, **scheduler**, **cyclecloud**, **winviz**, and **lustre**: Configuration properties of Azure VMs hosting the infrastructure components.
   - **users**: User accounts auto provisioned as part of the deployment.
   - **queue_manager**: The name of the scheduler to be installed and configured, which is **openpbs** by default.
   - **authentication**: The authentication method, which is **basic** by default. But you have the option of using **OpenID Connect** instead.
   - **images**: The list of images that will be available for deployment of compute cluster nodes and their respective configuration.
   - **queues**: The list of node arrays of CycleCloud and their respective configuration.

1. If needed, change the name of the target Azure region set in the **config.yml** file to the one you are using in this lab, save the change, and then close the file.

### Task 2: Deploy Azure HPC OnDemand Platform infrastructure

1. Within the SSH session to the Azure VM, run the following command to generate a Terraform deployment plan that includes the listing of all resources to be provisioned:

   ```bash
   ./build.sh -a plan
   ```

1. Review the generated list of resources, and then run the following command to trigger the deployment of the Azure HPC OnDemand Platform infrastructure:

   ```bash
   ./build.sh -a apply
   ```

   > ![Note]: Wait for the deployment to complete. This should take about 20 minutes. After the deployment completes, you should observe the message stating **Apply complete! Resources: 124 added, 0 changed, 0 destroyed.**

### Task 3: Build images

The az-hop solution provides pre-configured Packer configuration files that can be used to build custom images. The utility script **./packer/build_image.sh** performs the build process and stores the resulting images in the Shared Image Gallery included in the deployed infrastructure.

1. On the lab computer, in the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following commands to build a custom image based on the **azhop-centos79-v2-rdma-gpgpu.json** configuration file.

   > ![Note]: The image creation process based on the **azhop-centos79-v2-rdma-gpgpu.json** configuration file relies on a **Standard_d8s_v3** SKU Azure VM.

   ```bash
   cd packer/
   ./build_image.sh -i azhop-centos79-v2-rdma-gpgpu.json
   ```

   > ![Note]: Disregard any warning messages.

   > ![Note]: Wait for the process to complete. This might take about 20 minutes.

   > ![Note]: The image creation process based on the **centos-7.8-desktop-3d.json** configuration file relies on a **Standard_NV6** SKU Azure VM. If you manage to obtain a sufficient number of quotas to provision a **Standard_NV6**-based Azure VM, you can proceed directly to the next step. Otherwise, open the **centos-7.8-desktop-3d.json** file, replace the entry **Standard_NV6** with **Standard_D8s_v3**, save the change, and then close the file. Although such a step is likely to affect the functionality of compute resources based on this image, its meant strictly as a workaround that facilitates the next step in the process of implementing the Azure HPC OnDemand Platform lab environment.

1. Within the SSH session to the Azure VM, run the following command to build a custom image based on the **centos-7.8-desktop-3d.json** configuration file.

   ```bash
   ./build_image.sh -i centos-7.8-desktop-3d.json
   ```

   > ![Note]: Wait for the process to complete. This might take about 40 minutes.

### Task 4: Review deployment results

1. On the lab computer, in the browser window displaying the Azure portal, open another tab, navigate to the Azure portal, use the **Search resources, services, and docs** text box to search for **Azure compute galleries**, and in the list of results, select **Azure compute galleries**.
1. On the **Azure compute galleries** blade, select the entry whose name starts with the prefix **azhop** and then on the compute gallery blade, verify that the gallery includes two VM image definitions.
1. In the Azure portal, use the **Search resources, services, and docs** text box to search for **Azure virtual machines**, and in the list of results, select **Virtual machines**.
1. On the **Virtual machines** blade, review the listing of the provisioned virtual machines.

   > ![Note]: If needed, filter the listing of the virtual machines by setting the resource group criterion to **azhop**.

1. Close the newly opened browser tab displaying the **Virtual machines** blade in the Azure portal.

### Task 5: Generate passwords for user and admin accounts

1. On the lab computer, in the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following command to generate the password for the **clusteradmin** and **clusteruser** accounts defined in the **config.yml** configuration file:

   ```bash
   cd ~/az-hop/
   ./create_passwords.sh
   ```

1. Run the following command to display the newly generated password of the **clusteradmin** account:

   ```bash
   ./bin/get_secret clusteradmin
   ```

   > ![Note]: Record the password. You will need it later in this lab.

   > ![Note]: The **./bin/get_secret utility script** retrieves the password of the user you specify as its parameter from the Azure Key vault, which is part of the Azure HPC OnDemand Platform infrastructure you deployed in the previous exercise.

## Exercise 3: Install and configure Azure HPC OnDemand Platform software components

Duration: 50 minutes

In this exercise, you'll install and configure software components that form the Azure HPC OnDemand Platform solution.

> ![Note]: You will perform this installation by using Ansible playbooks, which supports setup for individual components and an entire solution. In either case, its necessary to account for dependencies between components. The setup script **install.sh** in the root directory of the repository performs the installation in the intended order. The components include: **ad**, **linux**, **add_users**, **lustre**, **ccportal**, **cccluster** (this component requires that custom images are present in the compute gallery), **scheduler**, **ood**, **grafana**, **telegraf**, and **chrony**.

### Task 1: Install and configure Azure HPC OnDemand Platform software components

1. On the lab computer, in the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following command to invoke the installation of the Azure HPC OnDemand Platform software components:

   ```bash
   ./install.sh
   ```

   > ![Note]: Wait for the process to complete. This might take about 30 minutes.

   > ![Note]: In case of a transient failure, you can rerun the install script can be rerun because most of the settings are idempotent. In addition, the script has a checkpointing mechanism that creates component-specific files with the **.ok** extension in the playbooks directory and checks for their presence during subsequent runs. If you want to reapply the configuration to an existing component, delete the corresponding **.ok** file, and then rerun the install script.

### Task 2: Review installation results

1. After the installation completes, on the lab computer, in the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following command to display the URL of the Azure HPC On-Demand Platform portal:

   ```bash
   grep ondemand_fqdn playbooks/group_vars/all.yml
   ```

   > ![Note]: Record this value. You'll need it throughout the remainder of this lab.

1. From the lab computer, start a web browser, navigate to the URL of the Azure HPC On-Demand Platform portal you identified earlier in this task, and when prompted sign in with the **clusteradmin** user account and its password you identified in the previous step.

   > ![Note]: You'll be presented with the **Azure HPC On-Demand Platform** dashboard. Review its interface, starting with the top-level menu, which provides access to **Apps**, **Files**, **Jobs**, **Clusters**, **Interactive Apps**, **Monitoring**, and **My Interactive Sessions** menu items.

1. In the **Monitoring** menu, select **Azure CycleCloud**.
1. When presented with the page titled **App has not been initialized or does not exist**, select **Initialize App**.

   > ![Note]: This prompt reflects the OnDemand component architecture, which the Azure HPC OnDemand Platform solution relies on to implement its portal. The shared frontend creates Per User NGINX (PUN) processes to provide connectivity to such components as **Azure CycleCloud**, **Grafana**, or **Robinhood Dashboard**.

1. On the **Azure CycleCloud for Azure HPC On-Demand Platform** page, note the presence of a configuration of a cluster named **pbs1**.
1. On the **pbs1** page, select the **Arrays** tab, and note that it contains six entries representing queue definitions you reviewed earlier in the **config.yml** file.

## Exercise 4: Review the main az-hop features

Duration: 60 minutes

In this exercise, you will review the main features of the Azure HPC OnDemand Platform lab environment.

### Task 1: Using file explorer

> ![Note]: For more information regarding this topic, refer to [https://azure.github.io/az-hop/user_guide/files.html](https://azure.github.io/az-hop/user_guide/files.html)

> ![Note]: You can access your home directory files directly from the OnDemand interface.

1. On the lab computer, in the browser window, in the **Azure HPC On-Demand Platform** portal, select the **Files** menu. Then, from the drop-down menu, select **Home Directory**.
1. On the **Home Directory** page, review its interface, including the options to:

   - Create directories and files.
   - Upload and download files.
   - Perform copy and move operations.
   - Delete directories and files.
   - Open the terminal window in the current file system location.

### Task 2: Using shell access

> ![Note]: For more information regarding this topic, refer to [https://azure.github.io/az-hop/user_guide/clusters.html](https://azure.github.io/az-hop/user_guide/clusters.html)

1. In the **Azure HPC On-Demand Platform** portal, select the **Clusters** menu, and then from the drop-down menu, select **AZHOP - Cluster Shell Access**.

   > ![Note]: This will open another browser tab displaying a shell session to the cluster.

1. In the shell session, run the following command to submit a simple test job:

   ```bash
   qsub -l select=1:slot_type=execute -- /usr/bin/bash -c 'sleep 60'
   ```

   > ![Note]: Do not paste commands into the shell session pane, enter them instead.

1. In the shell session, run the following command to display the status of the submitted job:

   ```bash
   qstat
   ```

   > ![Note]: Examine the output of the command and verify that the submitted job is in the queue.

1. Switch to the browser tab with the **Azure CycleCloud for Azure HPC On-Demand Platform** page.
1. Review the newly created job's progress, including the new VM creation.

### Task 3: Running interactive apps using Code Server and Remote Desktop

> ![Note]: For more information regarding this topic, refer to [https://azure.github.io/az-hop/user_guide/code_server.html](https://azure.github.io/az-hop/user_guide/code_server.html) and [https://azure.github.io/az-hop/user_guide/remote_desktop.html](https://azure.github.io/az-hop/user_guide/remote_desktop.html)

1. On the lab computer, in the browser window, switch to the tab displaying the **Azure HPC On-Demand Platform** portal.
1. Select the **Interactive Apps** menu, and then from the drop-down menu, select **Code Server**.

   > ![Note]: This will open another browser tab displaying the **Code Server** launching page.

1. On the **Code Server** launching page, in the **Maximum duration of your remote session** field, enter **1**. In the **Slot Type** text box, enter **execute**, and then select **Launch**.

   > ![Note]: This will initiate the provisioning of a compute node of the type you specified. Note that this creates a new job and the **Queued** status for this job is displayed on the same page.

1. Switch to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the **execute** node provisioning's progress.

   > ![Note]: Wait until the node status changes to **Ready**. This should take about 5 minutes.

1. Switch back to the **Code Server** launching page.
1. Verify that the corresponding job's status has changed to **Running**, and then select **Connect to VS Code**.

   > ![Note]: This will open another browser tab displaying the Code Server interface.

1. Review the interface, and then close the **Welcome** tab.
1. In the top left corner of the page, select the **Application** menu. From the drop-down menu, select **Terminal**, and then in the cascading menu, select **New Terminal**.
1. In the **Terminal** pane, at the **[clusteradmin@execute-1 ~]$** prompt, enter `qstat` to observe the currently running job.
1. Switch back to the **Code Server** launching page.
1. In the **Interactive Apps** section, select **Remote Desktop**.
1. On the **Remote Desktop** launching page, from the **Session target** drop-down list, ensure that **Without GPU** is selected.
1. In the **Maximum duration of your remote session** field, enter **1**,  and then select **Launch**.

   > ![Note]: This will begin compute node provisioning of the type you specified. This also creates a new job with its **Queued** status displaying on the same page.

1. Switch back to the **Remote Desktop** launching page.
1. From the **Session target** drop-down list, select **With GPU**.
1. In the **Maximum duration of your remote session** field, enter **1**,  and then select **Launch**.

   > ![Note]: The ability to extend the time you specify is not supported. After the time you specified passes, the session terminates. However, you can choose to terminate the session early.

   > ![Note]: This will initiate the provisioning of a compute node of the type you specified. Note that this creates a new job and the **Queued** status for this job is displayed on the same page.

1. Switch to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the progress of the **viz** and **viz3d** node provisioning.

   > ![Note]: Wait until the status of the node changes to **Ready**. This should take about 5 minutes.

   > ![Note]: The **viz3d** node provisioning will fail if your subscription doesn't offer **Standard_NV6** SKU in the Azure region hosting your az-hop deployment.

1. Switch back to the **Remote Desktop** launching page, and then verify that the corresponding job's status has changed to **Running**.
1. Adjust **Compression** and **Image quality** according to your preferences, and then select **Launch Remote Desktop**.

   > ![Note]: This will open another browser tab displaying the Remote Desktop VNC session.

1. Switch back to the **Remote Desktop** launching page and use the **Delete** button to delete the **Code Server** and **Remote Desktop** jobs by selecting **Confirm** when prompted.

### Task 4: Running Intel MPI PingPong jobs from the Job composer

1. On the lab computer, in the browser window displaying the Azure HPC On-Demand Platform portal, navigate to the **Dashboard** page.
On the **Dashboard** page, select the **Jobs** menu title, and from the drop-down menu, select **Job Composer**.
1. On the **Jobs** page, select **+ New job**, and from the drop-down menu, select **From Default Template**.

   > ![Note]: This will automatically create a job named **(default) Sample Sequential Job** that targets the **execute** CycleCloud array. To identify the content of the job script, ensure that the newly created job is selected, and then review the **Script contents** pane.

1. Repeat the previous step twice to create two additional jobs based on the default template.

   > ![Note]: The default job template contains a trivial script that runs `echo "Hello World"`.

1. Note that all three jobs are currently in the **Not Submitted** state. To submit them, select each one of them, and then select **Submit**.

   > ![Note]: The status of the jobs should change to **Queued**.

1. On the lab computer, in the browser window displaying the Azure HPC On-Demand Platform portal, select the **Azure HPC On-Demand Platform** header. Select the **Monitoring** menu, and from the drop-down list, select **Azure CycleCloud**.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, monitor the status of the cluster and note that the number of nodes increases to **3**, which initially are listed in the **acquiring** state.
1. On the **Nodes** tab, verify that **execute** appears in the **Template** column, the **Nodes** column contains the entry **3**, and the **Last status** column displays the **Creating VM** message.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, on the **pbs1** page, select the **Scalesets** tab. Note a scaleset that hosts the cluster nodes with its size set to **3**.
1. Select the entry on the **Nodes** tab, and then review the details of the cluster nodes in the lower section of the page, including:
   - The name of each node
   - The status of each node
   - The number of cores
   - The placement group
1. Navigate to the **Azure HPC On-Demand Platform** portal
1. Select the **Jobs** menu, and from the drop-down menu, select **Active jobs**.
1. On the **Active jobs** page, verify that three active jobs are listed in the **Queued** status.
1. Navigate to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, and then monitor the progress of node provisioning.

   > ![Note]: Wait until the status of nodes changes to **Ready**. This should take about 5 minutes.

1. After the nodes' status changes to **Ready**, switch to the **Active jobs** page.
1. Refresh the **Active jobs** page and note that the jobs are no longer listed.

   > ![Note]: If the jobs are still listed as **Queued**, wait for a few more minutes, and then refresh the page again.

1. Navigate back to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the node status until it changes to terminating, which will result eventually in their deletion.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, on the **pbs1** page, select the **Scalesets** tab.
1. Note that the scaleset hosting the cluster nodes persists but its size is set to **0**.

### Task 5: Create jobs based on a non-default Azure HPC OnDemand Platform template

1. On the lab computer, in the browser window, switch back to the **Azure HPC On-Demand Platform** portal.
1. Select the **Jobs** menu, and from the drop-down menu, select **Job Composer**.
1. On the **Jobs** page, select **Templates**.
1. On the **Templates** page, in the list of predefined templates, select the **Intel MPI PingPong** entry, and then select **Copy Template**.

   > ![Note]: The Message Passing Interface (MPI) ping-pong tests measure network latency and throughput between nodes in the cluster by sending packets of data back and forth between paired nodes repeatedly. The *latency* is the average of half of the time that it takes for a packet to make a round trip between a pair of nodes, in microseconds. The *throughput* is the average rate of data transfer between a pair of nodes, in MB/second.

1. On the **New Template** page, specify the following settings, and then select **Save**:

   |Setting|Value|
   |---|---|
   |Name|**Intel MPI PingPong v2**|
   |Cluster|**AZHOP - Cluster**|
   |Name|**<p>A very basic template for running Intel MPI ping pong on hb120v2</p>**|

1. On the **Templates** page, select the newly created template, and then select **View Files**.
1. On the page listing the files that are part of the template, in the **pingpong.sh** row, select the square icon containing the vertical ellipsis symbol, and then from the drop-down menu, select **Edit**.
1. On the page displaying the **pingpong.sh** script content, in the third line, replace `slot_type=hb120v3` with `slot_type=hb120v2`, and then select **Save**.
1. Navigate to the **Jobs** page.
1. Select **+ New job**, and then from the drop-down menu, select **From Template**.
1. On the **Templates** page, ensure that the **Intel MPI PingPong v2** entry is selected, and then select **Create New Job**.

   > ![Note]: This will automatically create a job named **Intel MPI PingPong v2** that targets the **hb120v2** CycleCloud array.

1. Repeat the previous step twice to create two additional jobs based on the **Intel MPI PingPong v2** template.
1. Note that, as before, all three jobs are currently in the **Not Submitted** state. To submit them, select each one of them, and then select **Submit**.

   > ![Note]: The status of the jobs should change to **Queued**.

1. Navigate to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the node provisioning progress.

   > ![Note]: Wait until the nodes' status changes to **Ready**. This should take about 5 minutes.

1. After the node status changes to **Ready**, switch back to the **Active jobs** page, and then refresh it. Note that the jobs are no longer listed.

   > ![Note]: If the jobs are still listed as **Queued**, wait for a few more minutes, and then refresh the page again.

1. Navigate to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the node status until it changes to terminating, resulting eventually in their deletion.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, on the **pbs1** page, select the **Scalesets** tab.
1. Note that the scaleset hosting the cluster nodes persists but its size is set to **0**.
1. To review the job output, switch to the **Azure HPC On-Demand Platform** portal, select the **Jobs** menu, and then from the drop-down menu, select **Job Composer**.
1. On the **Jobs** page, select any of the **Intel MPI PingPong v2** job entries, and in the **Folder Contents** section, select **PingPong.o3**.

   > ![Note]: This will automatically open another web browser tab displaying the output of the job.

## Exercise 5: Set up Spack

Duration: 30 minutes

In this exercise, you will install and configure Spack from Code Server, as documented in [https://azure.github.io/az-hop/tutorials/spack.html](https://azure.github.io/az-hop/tutorials/spack.html).

### Task 1: Create a compute node

1. On the lab computer, in the browser window, switch to the tab displaying the **Azure HPC On-Demand Platform** portal.
1. Select the **Interactive Apps** menu, and from the drop-down menu, select **Code Server**.

   > ![Note]: This will open another browser tab displaying the **Code Server** launching page.

1. On the **Code Server** launching page, in the **Maximum duration of your remote session** field, enter **3**. In the **Slot Type** text box, enter **execute**, and then select **Launch**.

   > ![Note]: This will initiate the provisioning of a compute node of the type you specified. Note that this creates a new job and the **Queued** status for this job is displayed on the same page.

1. Switch to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the progress of the **execute** node provisioning.

   > ![Note]: Wait until the node status changes to **Ready**. This should take about 5 minutes.

1. Switch back to the **Code Server** launching page, verify that the corresponding job's status has changed to **Running**, and then select **Connect to VS Code**.

   > ![Note]: This will open another browser tab displaying the Code Server interface.

1. Review the interface, and then close the **Welcome** tab.
1. Select the **Application** menu, from the drop-down menu select **Terminal**, and then from the sub-menu that opens, select **New Terminal**.
1. In the **Terminal** pane, at the **[clusteradmin@execute-1 ~]$** prompt, run the following command to clone the azurehpc repo and use the azhop/spack branch:

   ```bash
   git clone https://github.com/Azure/azurehpc.git
   ```

1. In the Terminal pane, run the following command to provision a compute node and connect to it interactively:

   ```bash
   qsub -l select=1:slot_type=hb120v3 -I
   ```

   > ![Note]: Wait for the node to finish provisioning. This might take about 10 minutes.

### Task 2: Install Spack

1. On the lab computer, in the browser window displaying the Code Server, wait until the prompt **[clusteradmin@hb120v3-1 ~]$** appears within the **Terminal** pane.
1. In the **Terminal** pane, run the following commands to install and configure Spack:

   ```bash
   ~/azurehpc/experimental/azhop/spack/install.sh
   ~/azurehpc/experimental/azhop/spack/configure.sh
   ```

   > ![Note]: The output should resemble the following listing:

   ```bash
   [clusteradmin@hhb120v3-1 ~]$ ~/azurehpc/experimental/azhop/spack/install.sh
   Cloning into '/anfhome/clusteradmin/spack'...
   remote: Enumerating objects: 356062, done.
   remote: Counting objects: 100% (8/8), done.
   remote: Compressing objects: 100% (7/7), done.
   remote: Total 356062 (delta 0), reused 5 (delta 0), pack-reused 356054
   Receiving objects: 100% (356062/356062), 161.30 MiB | 20.68 MiB/s, done.
   Resolving deltas: 100% (151608/151608), done.
   Checking out files: 100% (9104/9104), done.
   Checking out files: 100% (8002/8002), done.
   Branch releases/v0.16 set up to track remote branch releases/v0.16 from origin.
   Switched to a new branch 'releases/v0.16'
   [clusteradmin@hb120v3-1 ~]$ ~/azurehpc/experimental/azhop/spack/configure.sh
   Add GCC compiler
   ==> Added 1 new compiler to /anfhome/clusteradmin/.spack/linux/compilers.yaml
       gcc@9.2.0
   ==> Compilers are defined in the following files:
       /anfhome/clusteradmin/.spack/linux/compilers.yaml
   Configure external MPI packages
   Configure local settings
   ```

1. In the **Terminal** pane, run the following commands to confirm the list of defined compilers:

   ```bash
   . ~/spack/share/spack/setup-env.sh
   spack compilers
   ```

   > ![Note]: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v3-1 ~]$ . ~/spack/share/spack/setup-env.sh
   [clusteradmin@hb120v3-1 ~]$ spack compilers
   ==> Available compilers
   -- gcc centos7-x86_64 -------------------------------------------
   gcc@9.2.0
   ```

   > ![Note]: Verify that gcc 9.2 is referenced in the output.

## Exercise 6: Build, run, and analyze reservoir simulation using OPM Flow

In this exercise, you will build, run, and analyze reservoir simulation using OPM (Open Porous Media) Flow.

Duration: 60 minutes

### Task 1: Build OPM

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v3-1 ~]$**  prompt, run the following command to load Spack modules:

   ```bash
   module use /usr/share/Modules/modulefiles
   ```

1. Run the following command to create the az-hop Spack repo:

   ```bash
   ~/azurehpc/experimental/azhop/azhop-spack/install.sh
   ```

   > ![Note]: The output should resemble the following listing:

   ```bash
   ==> Added repo with namespace 'azhop'.
   ```

1. Run the following command to configure the OPM packages:

   ```bash
   ~/azurehpc/experimental/azhop/opm/configure.sh
   ```

   > ![Note]: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v3-1 ~]$ ~/azurehpc/experimental/azhop/opm/configure.sh
   Cloning into 'dune-spack'...
   remote: Enumerating objects: 357, done.
   remote: Total 357 (delta 0), reused 0 (delta 0), pack-reused 357
   Receiving objects: 100% (357/357), 74.34 KiB | 0 bytes/s, done.
   Resolving deltas: 100% (179/179), done.
   ==> Added repo with namespace 'dune'.
   ```

1. Run the following command to list available modules:

   ```bash
   module use /usr/share/Modules/modulefiles
   module avail
   ```

   > ![Note]: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v3-1 .spack]$ module avail

   ---------------------------------------- /usr/share/Modules/modulefiles ----------------------------------------
      amd/aocl              module-git         mpi/hpcx               mpi/impi-2021         mpi/openmpi-4.1.0 (D)
      amd/aocl-2.2-4 (D)    module-info        mpi/impi_2018.4.274    mpi/mvapich2          null
      dot                   modules            mpi/impi_2021.2.0      mpi/mvapich2-2.3.5    use.own
      gcc-9.2.0             mpi/hpcx-v2.8.3    mpi/impi               mpi/openmpi

   ------------------------------------ /usr/share/lmod/lmod/modulefiles/Core -------------------------------------
      lmod    settarg

     Where:
      D:  Default Module

   Use "module spider" to find all possible modules and extensions.
   Use "module keyword key1 key2 ..." to search for all possible modules matching any of the "keys".
   ```

   > ![Note]: Review the output and note the openmpi version.

1. Use your preferred text editor to update the **~/.spack/packages.yaml** file content by replacing references to **hpcx** with **openmpi**, removing **hpcx**-related entries, and if necessary, updating the openmpi version to the one you identified in the previous step.

   > ![Note]: The following example is sample content from the **~/.spack/packages.yaml** file:

   ```bash
   packages:
     all:
       target: [x86_64]
       providers: 
         mpi: [hpcx]
     openmpi:
       externals:
       - spec: openmpi@4.0.5%gcc@9.2.0
         modules:
         - mpi/openmpi-4.0.5
       buildable: False
     hpcx:
       externals:
       - spec: hpcx@2.7.4%gcc@9.2.0
         modules:
         - mpi/hpcx-v2.7.4
       buildable: False
   ```

   > ![Note]: You must use the following updated content with openmpi version 4.1.0.

   ```bash
   packages:
     all:
       target: [x86_64]
       providers: 
         mpi: [openpmi]
     openmpi:
       externals:
       - spec: openmpi@4.1.0%gcc@9.2.0
         modules:
         - mpi/openmpi-4.1.0
       buildable: False
   ```

1. Run the following command to initialize the OPM build:

   ```bash
   ~/azurehpc/experimental/azhop/opm/build.sh
   ```

   > ![Note]: The output should start with the following listing:

   ```bash
   [clusteradmin@hb120v3-1 ~]$ ~/azurehpc/experimental/azhop/opm/build.sh
   ==> Warning: Missing a source id for openmpi@4.1.0
   ==> Warning: Missing a source id for dune@2.7
   ==> Installing pkg-config-0.29.2-opt4cajmlefjsbaqmhcuxegkkdr6gvac
   ==> No binary for pkg-config-0.29.2-opt4cajmlefjsbaqmhcuxegkkdr6gvac found: installing from source
   ==> Fetching https://mirror.spack.io/_source-cache/archive/6f/6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591.tar.gz
   ######################################################################## 100.0%
   ==> pkg-config: Executing phase: 'autoreconf'
   ==> pkg-config: Executing phase: 'configure'
   ```

   > ![Note]: Wait for the build to complete. This might take about 30 minutes.

### Task 2: Retrieve test data and run a flow job

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v3-1 ~]$** prompt, run the following commands to download test data:

   ```bash
   cd /lustre
   mkdir clusteradmin
   cd clusteradmin
   git clone https://github.com/OPM/opm-data.git
   ```

1. Run the following command to copy the **~/azurehpc/experimental/azhop/opm/run_opm.sh** file to the home directory:

   ```bash
   cp ~/azurehpc/experimental/azhop/opm/run_opm.sh ~
   ```

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v3-1 ~]$** prompt, open the newly created copy of the **run_opm.sh** file in a text editor.
1. Make the following changes to the file, and close it after saving the changes:

   - Modify the input file path (`INPUT`) by replacing the entry `~/opm-data/norne` with `/lustre/clusteradmin/opm-data/norne`).
   - Modify the compute node configuration by replacing the entry `select=1:ncpus=40:mpiprocs=40:slot_type=hc44rs` with `select=1:ncpus=120:mpiprocs=60:slot_type=hb120v3`.
   - Add the `which flow` line following the `spack load opm-simulators` line.

   > ![Note]: Leave the number of nodes set to **1** to avoid the quota limit issues.

   > ![Note]: The original **run_opm.sh** file has the following content:

   ```bash
   #!/bin/bash
   #PBS -N OPM
   #PBS -l select=1:ncpus=40:mpiprocs=40:slot_type=hc44rs
   #PBS -k oed
   #PBS -j oe
   #PBS -l walltime=3600

   INPUT=~/opm-data/norne/NORNE_ATW2013.DATA
   INPUT_DIR=${INPUT%/*}
   INPUT_FILE=${INPUT##*/}
   NUM_THREADS=1

   . ~/spack/share/spack/setup-env.sh
   module use /usr/share/Modules/modulefiles
   spack load opm-simulators

   pushd $INPUT_DIR
   CORES=`cat $PBS_NODEFILE | wc -l`

   mpirun  -np $CORES \
           -hostfile $PBS_NODEFILE \
           --map-by numa:PE=$NUM_THREADS \
           --bind-to core \
           --report-bindings \
           --display-allocation \
           -x LD_LIBRARY_PATH \
           -x PATH \
           -wd $PWD \
           flow --ecl-deck-file-name=$INPUT_FILE \
                --output-dir=$INPUT_DIR/out_parallel \
                --output-mode=none \
                --output-interval=10000 \
                --threads-per-process=$NUM_THREADS
   popd
   ```

   > ![Note]: The modified **run_opm.sh** file should have the following content:

   ```bash
   #!/bin/bash
   #PBS -N OPM
   #PBS -l select=1:ncpus=120:mpiprocs=60:slot_type=hb120v3
   #PBS -k oed
   #PBS -j oe
   #PBS -l walltime=3600

   INPUT=/lustre/clusteradmin/opm-data/norne/NORNE_ATW2013.DATA
   INPUT_DIR=${INPUT%/*}
   INPUT_FILE=${INPUT##*/}
   NUM_THREADS=1

   . ~/spack/share/spack/setup-env.sh
   module use /usr/share/Modules/modulefiles
   spack load opm-simulators
   which flow

   pushd $INPUT_DIR
   CORES=`cat $PBS_NODEFILE | wc -l`

   mpirun  -np $CORES \
           -hostfile $PBS_NODEFILE \
           --map-by numa:PE=$NUM_THREADS \
           --bind-to core \
           --report-bindings \
           --display-allocation \
           -x LD_LIBRARY_PATH \
           -x PATH \
           -wd $PWD \
           flow --ecl-deck-file-name=$INPUT_FILE \
                --output-dir=$INPUT_DIR/out_parallel \
                --output-mode=none \
                --output-interval=10000 \
                --threads-per-process=$NUM_THREADS
   popd
   ```

1. On the lab computer, in the browser window displaying the Code Server, in the Terminal pane, from the prompt **[clusteradmin@hb120v3-1 ~]$**, run the following command to submit the job referenced in the **~/run_opm.sh** file:

   ```bash
   qsub ~/run_opm.sh 
   ```

1. Run the following command to verify that the job has been queued:

   ```bash
   qstat
   ```

   > ![Note]: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v3-1 clusteradmin]$ qsub ~/run_opm.sh
   8.scheduler
   [clusteradmin@hb120v3-1 clusteradmin]$ qstat
   Job id            Name             User              Time Use S Queue
   ----------------  ---------------- ----------------  -------- - -----
   6.scheduler       sys-dashboard-s  clusteradmin      00:00:17 R workq           
   7.scheduler       STDIN            clusteradmin      03:24:08 R workq           
   8.scheduler       OPM              clusteradmin             0 Q workq  
   ```

   > ![Note]: Review the output to identify the job name.

1. In the previous command's output, identify the **Job id** of the newly submitted job.
1. Run the following command to display the newly submitted job's status by replacing the `<jobid>` placeholder in the following command with the value you identified:

   ```bash
   qstat -fx <jobid>
   ```

   > ![Note]: The output should start with the following listing:

   ```bash
   [clusteradmin@hb120v3-1 clusteradmin]$ qstat -fx 8.scheduler
   Job Id: 8.scheduler
       Job_Name = OPM
       Job_Owner = clusteradmin@hb120v3-1.internal.cloudapp.net
       resources_used.cpupercent = 1635
       resources_used.cput = 00:45:00
       resources_used.mem = 29380680kb
       resources_used.ncpus = 120
       resources_used.vmem = 117657196kb
       resources_used.walltime = 00:00:55
       job_state = F
       queue = workq
       server = scheduler
       Checkpoint = u
       ctime = Tue Feb 22 18:26:47 2022
       Error_Path = hb120v3-1.internal.cloudapp.net:/lustre/clusteradmin/OPM.e8
       exec_host = hb120v3-2/0*120
       exec_vnode = (hb120v3-2:ncpus=120)
       Hold_Types = n
       Join_Path = oe
       Keep_Files = oed
       Mail_Points = a
       mtime = Tue Feb 22 18:36:42 2022
       Output_Path = hb120v3-1.internal.cloudapp.net:/lustre/clusteradmin/OPM.o8
       Priority = 0
       qtime = Tue Feb 22 18:26:47 2022
       Rerunable = True
       Resource_List.mpiprocs = 60
       Resource_List.ncpus = 120
       Resource_List.nodect = 1
       Resource_List.place = scatter:excl
       Resource_List.select = 1:ncpus=120:mpiprocs=60:slot_type=hb120v3
       Resource_List.slot_type = execute
       Resource_List.ungrouped = false
       Resource_List.walltime = 01:00:00
       stime = Tue Feb 22 18:35:47 2022
       session_id = 12364
       jobdir = /anfhome/clusteradmin
       substate = 92
       Variable_List = PBS_O_HOME=/anfhome/clusteradmin,PBS_O_LANG=en_US.UTF-8,
           PBS_O_LOGNAME=clusteradmin,
           PBS_O_PATH=/anfhome/clusteradmin/spack/bin:/bin:/usr/bin:/usr/local/sb
           in:/usr/sbin:/opt/cycle/jetpack/bin:/opt/pbs/bin:/anfhome/clusteradmin/
           .local/bin:/anfhome/clusteradmin/bin,
           PBS_O_MAIL=/var/spool/mail/clusteradmin,PBS_O_SHELL=/bin/bash,
           PBS_O_WORKDIR=/lustre/clusteradmin,PBS_O_SYSTEM=Linux,
           PBS_O_QUEUE=workq,PBS_O_HOST=hb120v3-1.internal.cloudapp.net
       comment = Not Running: Not enough free nodes available
       etime = Tue Feb 22 18:26:47 2022
       run_count = 1
       Stageout_status = 1
       Exit_status = 0
       Submit_arguments = /anfhome/clusteradmin/run_opm.sh
       history_timestamp = 1645555002
       project = _pbs_project_default
   ```

   > ![Note]: Wait for the job to complete. This might take about 5 minutes.

   > ![Note]: To verify that the job completed, you can rerun the `qstat` command or the `qstat -fx <jobid>` command. The second command should display the comment in the format `comment = Job run at Tue Feb 22 at 18:40 on (hb120v3-2:ncpus=120) and finished`.

1. Run the following command to verify that the job has generated the expected output:

   ```bash
   ls /lustre/clusteradmin/opm-data/norne/out_parallel/
   ```

   > ![Note]: Alternatively, you can review the corresponding job-related `~/OPM.*` file content.

   > ![Note]: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v3-1 clusteradmin]$ ls /lustre/clusteradmin/opm-data/norne/out_parallel/
   NORNE_ATW2013.EGRID     NORNE_ATW2013.INIT  NORNE_ATW2013.SMSPEC  NORNE_ATW2013.UNSMRY
   NORNE_ATW2013.INFOSTEP  NORNE_ATW2013.RFT   NORNE_ATW2013.UNRST
   ```

### Task 3: Review the results of the OPM job by using ResInsight

1. On the lab computer, in the browser window, switch back to the **Azure HPC On-Demand Platform** portal, and then in the **Interactive Apps** section, select **Remote Desktop**.
1. On the **Remote Desktop** launching page, from the **Session target** drop-down list, ensure that **With GPU** entry is selected. In the **Maximum duration of your remote session** field, enter **1**,  and then select **Launch**.

   > ![Note]: In case your subscription doesn't have a sufficient number of quotas for the **Standard_NV6** SKU, choose the **Without GPU** entry instead.

   > ![Note]: This will begin compute node provisioning of the type you specified. This also creates a new job with its **Queued** status displaying on the same page.

1. Switch back to the **Remote Desktop** launching page, and then verify that the corresponding job's status has changed to **Running**.
1. Adjust **Compression** and **Image quality** according to your preferences, and then select **Launch Remote Desktop**.

   > ![Note]: This will open another browser tab displaying the Remote Desktop session.

1. Within the Remote Desktop session, start **Terminal Emulator**.

   > ![Note]: ResInsight installation instructions are available at [https://resinsight.org/getting-started/download-and-install/linux-installation/](https://resinsight.org/getting-started/download-and-install/linux-installation/)

1. In the **Terminal Emulator** window, at the **[clusteradmin@vis-1 ~]$** prompt, run the following commands to sudo to root:

   ```bash
   sudo su -
   ```

1. In the **Terminal Emulator** window, use the vi Editor to open the **/etc/yum.conf** file.
1. Add a new line with the `sslverify=0` entry.
1. Save the change, and then close the file.

   > ![Note]: This entry is necessary to prevent the error message **Peer's Certificate issuer is not recognized** when downloading the ResInsight package.

1. In the **Terminal Emulator** window, at the **[clusteradmin@vis-1 ~]$** prompt, run the following command to install the ResInsight package:

   ```bash
   yum-config-manager --add-repo https://opm-project.org/package/opm.repo
   yum install resinsight -y
   yum install resinsight-octave -y
   ```

1. In the **Terminal Emulator** window, at the **[clusteradmin@vis-1 ~]$** prompt, run the following command to launch ResInsight:

   ```bash
   exit
   vglrun ResInsight
   ```

   > ![Note]: This will open the ResInsight application window.

   > ![Note]: If you're using a non-GPU VM SKU, rather than running `vglrun ResInsight, you'll need to launch ResInsight directly. To do this, in the **Remote Desktop** session, select **Application Finder** (the magnifying glass icon at the bottom, center section of the page). In the search text box, enter **ResInsight**. From the list of search results, select **ResInsight**, and then select **Launch**.

1. In the ResInsight application window, select the **File** menu header. From the drop-down menu, select **Import**, in the sub-menu, select **Eclipse cases**, and then select **Import Eclipse cases**.
1. In the **Import Eclipse File** dialog box, select **Computer**.
1. Navigate to **/lustre/clusteradmin/opm-data/norne/out_parallel**, and then from the list of files in the target directory, select **NORNE_ATW2013.EGRID**.
1. Review the case in the ResInsight application window.

## Exercise 7: Deprovision Azure HPC OnDemand Platform environment

Duration: 30 minutes

In this exercise, you will deprovision the Azure HPC OnDemand Platform lab environment.

### Task 1: Terminate the cluster

1. On the lab computer, in the browser window, navigate to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal.
1. On the **pbs1** page, select **Terminate**, and when prompted for confirmation, select **OK**.
1. Monitor the cluster's termination progress.

   > ![Note]: Ensure that all nodes and scaleset are deleted before you proceed to the next step.

### Task 2: Deprovision the Azure resources

1. On the lab computer, switch to the browser window displaying the Azure portal
1. Start a Bash session in **Cloud Shell**.
1. From the Bash session in the **Cloud Shell** pane, run the following command to initiate the deprovisioning of the Azure HPC OnDemand Platform infrastructure you created and evaluated in this lab:

   ```bash
   az group delete --name azhop --yes
   ```

   > ![Note]: Wait for the resource deprovisioning to complete. This should take about 20 minutes.

<!-- TOC -->

- [Azure HPC OnDemand Platform lab guide](#azure-hpc-on-demand-platform-lab-guide)
  - [Requirements](#requirements)
  - [Before the hands-on lab](#before-the-hands-on-lab)
    - [Task 1: Validate the owner role assignment in the Azure subscription](#task-1-validate-the-owner-role-assignment-in-the-azure-subscription)
    - [Task 2: Validate a sufficient number of vCPU cores](#task-2-validate-a-sufficient-number-of-vcpu-cores)
  - [Exercise 1: Prepare for implementing the Azure HPC OnDemand Platform environment](#exercise-1-prepare-for-implementing-the-azure-hpc-ondemand-platform-environment)
    - [Task 1: Provision an Azure VM running Linux](#task-1-provision-an-azure-vm-running-linux)
    - [Task 2: Deploy Azure Bastion](#task-2-deploy-azure-bastion)
    - [Task 3: Install the az-hop toolset](#task-3-install-the-az-hop-toolset)
    - [Task 4: Prepare the Azure subscription for deployment](#task-4-prepare-the-azure-subscription-for-deployment)
  - [Exercise 2: Implement Azure HPC OnDemand Platform infrastructure](#exercise-2-implement-azure-hpc-ondemand-platform-infrastructure)
    - [Task 1: Customize infrastructure components](#task-1-customize-infrastructure-components)
    - [Task 2: Deploy Azure HPC OnDemand Platform infrastructure](#task-2-deploy-azure-hpc-ondemand-platform-infrastructure)
    - [Task 3: Build images](#task-3-build-images)
    - [Task 4: Review deployment results](#task-4-review-deployment-results)
    - [Task 5: Generate passwords for user and admin accounts](#task-5-generate-passwords-for-user-and-admin-accounts)
  - [Exercise 3: Install and configure Azure HPC OnDemand Platform software components](#exercise-3-install-and-configure-azure-hpc-ondemand-platform-software-components)
    - [Task 1: Install Azure HPC OnDemand Platform software components](#task-1-install-azure-hpc-ondemand-platform-software-components)
    - [Task 2: Review installation results](#task-2-review-installation-results)
  - [Exercise 6: Optionally - Deprovision Azure HPC OnDemand Platform environment](#exercise-6-optionally---deprovision-azure-hpc-ondemand-platform-environment)
    - [Task 1: Deprovision the Azure resources](#task-1-deprovision-the-azure-resources)

<!-- /TOC -->

# Azure HPC OnDemand Platform lab guide
This series of 2 labs will guide you in `Lab1` thru the whole deployment of an **azhop** environment, and in `Lab2` on how to use it.

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
1. On the **Check access** tab, select the **View my access** button, and in the listing of role assignments, verify that your user account has the `Owner` role assigned to it.

### Task 2: Validate a sufficient number of vCPU cores

1. In the Azure portal, on the subscription blade, in the **Settings** section of the resource menu, select **Usage + quota**.
1. On the **Usage + quotas** blade, in the **Search** filters drop-down boxes, select the Azure region you intend to use for this lab and the **Microsoft.Compute** provider entry.

   > Note: We recommend that you use the **South Central US**, **East US** or the **West Europe** regions because these currently are more likely to increase the possibility of successfully raising quota limits for the Azure virtual machine (VM) SKUs required for this lab.

1. Review the listing of existing quotas and determine whether you have sufficient capacity to accommodate a deployment of the following vCPUs:

   - Standard BS Family vCPUs: **12**
   - Standard DDv4 Family vCPUs: **64**
   - Standard DSv3 Family vCPUs: **16**
   - Standard DSv5 Family vCPUs: **48**
   - Standard HBrsv2 Family vCPUs: **480**
   - Standard NV Family vCPUs: **24**
   - Total Regional Spot vCPUs: **960**
   - Total Regional vCPUs: **830**

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

   > Note: Typically, requests for quota increases are completed within a few hours, but its possible that the processing might take up to a few days.

## Exercise 1: Prepare for implementing the Azure HPC OnDemand Platform environment

Duration: 40 minutes

In this exercise, you will set up an Azure VM that you will use for deployment of the lab environment.

### Task 1: Provision an Azure VM running Linux

1. From the lab computer, start a web browser, navigate to [the Azure portal](http://portal.azure.com), and if needed, sign in with credentials of the account with the Owner role in the Azure subscription you will be using in this lab.
1. In the Azure portal, start a Bash session in **Cloud Shell**.

   > Note: If prompted, in the **Welcome to Azure Cloud Shell** window, select **Bash (Linux)**, and in the **You have no storage mounted** window, select **Create storage**.

1. In the **Bash** session, in the **Cloud Shell** pane, run the following command to select the Azure subscription in which you will provision the Azure resources in this lab. In the following command, replace the `<subscription_ID>` placeholder with the value of the **subscriptionID** property of the Azure subscription you are using in this lab:

   > Note: To list the subscription ID properties of all subscriptions associated with your account, run `az account list -otable --query '[].{subscriptionId: id, name: name, isDefault: isDefault}'`.

   ```bash
   az account set --subscription '<subscription_ID>'
   ```

1. Run the following commands to create an Azure resource group that will contain the Azure VM hosting the lab deployment tools. In the following commands, replace the `<Azure_region>` placeholder with the name of the Azure region you intend to use in this lab:

   > Note: You can use the `az account list-locations -o table` command to list the names of Azure regions available in your Azure subscription:

   ```bash
   LOCATION="<Azure_region>"
   RGNAME="azhop-cli-RG"
   az group create --location $LOCATION --name $RGNAME
   ```

1. Run the following commands to download the Azure Resource Manager template and the corresponding parameters file into the Cloud Shell home directory. You will use the template and file to provision the Azure VM that will host the lab deployment tools:

   ```bash
   rm ubuntu_azurecli_vm_template.json -f
   rm ubuntu_azurecli_vm_template.parameters.json -f

   wget https://raw.githubusercontent.com/azure/az-hop/main/scripts/arm/ubuntu_azurecli_vm_template.json
   wget https://raw.githubusercontent.com/azure/az-hop/main/scripts/arm/ubuntu_azurecli_vm_template.parameters.json
   ```

1. Run the following command to provision the Azure VM that will host the lab deployment tools:

   ```bash
   az deployment group create \
   --resource-group $RGNAME \
   --template-file ubuntu_azurecli_vm_template.json \
   --parameters @ubuntu_azurecli_vm_template.parameters.json
   ```

   > Note: When prompted, enter an arbitrary password that will be assigned to the **azureadm** user, which you will use to sign in to the operating system of the Azure VM.

   > Note: Wait until the provisioning completes. This should take about 3 minutes.

### Task 2: Deploy Azure Bastion

> Note: Azure Bastion allows users to connect to Azure VMs without relying on public endpoints and helps provide protection against brute force exploits that target operating system level credentials.

1. Close the **Cloud Shell** pane.
1. In the Azure Portal, select **Resource groups**, select the resource group you have created with the name `RGNAME`
1. Click on the VM named **azhop-vm0**,
1. Expand the **Connect** menu and select **Bastion**
1. As no Bastion already exists you are proposed to create one, select **Create Azure Bastion using defaults**
   > Note: Wait for the deployment to complete before you proceed to the next exercise. The deployment might take about 5 minutes to complete.
1. Enter **azureadm** as the user name and the password you set during the Azure VM deployment in the first task of this exercise, and then select **Connect**. You may have to disable the popup blocker as it may block the connection window. 
### Task 3: Install the az-hop toolset

1. Within the SSH session to the Azure VM, run the following command to update the package manager list of available packages and their versions:

   ```bash
   sudo apt-get update
   ```

1. Run the following command to upgrade the versions of the local packages and confirm when prompted whether to proceed:

   ```bash
   sudo apt-get upgrade -y
   ```

1. Run the following command to install Git and screen:

   ```bash
   sudo apt-get install git screen
   ```

1. Run the following commands to clone the **az-hop** repository:

   ```bash
   rm ~/az-hop -rf
   git clone --recursive https://github.com/Azure/az-hop.git -b v1.0.21
   ```

1. Run the following commands to install all the tools required to provision the **az-hop** environment:

   ```bash
   cd ~/az-hop/
   sudo ./toolset/scripts/install.sh
   ```

   > Note: Wait until the script completes running. This might take about 5 minutes.

### Task 4: Prepare the Azure subscription for deployment

1. Within the SSH session to the Azure VM, run the following command to sign in to the Azure subscription you are using in this lab:

   ```bash
   az login
   ```

1. Note the code displayed in the output of the command. Switch to your lab computer, open another tab in the browser window displaying the Azure portal, navigate to [the Microsoft Device Login page](https://microsoft.com/devicelogin), enter the code, and then select **Next**.
   > Note: You may use **select** and **right click** to copy selected text. Be careful that **ctrl+c** will interrupt the command

1. If prompted, sign in with the credentials of the user account with the Owner role in the Azure subscription you are using in this lab,  select **Continue**, and then close the newly opened browser tab.
1. In the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following command to identify the Azure subscription you are connected to:

   ```bash
   az account show
   ```

1. If the Azure subscription you are connected to is different from the one you intend to use in this lab, run the following command to change the subscription to which you are currently connected. In the following command, replace the `<subscription_ID>` placeholder with the value of the subscriptionID parameter of the Azure subscription you intend to use in this lab:

   ```bash
   az account set --subscription '<subscription_ID>'
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

   > Note: In the output of the command, verify that the value of **RegistrationState** is listed as **Registered**.

## Exercise 2: Implement Azure HPC OnDemand Platform infrastructure

Duration: 90 minutes

In this exercise, you will deploy the Azure HPC OnDemand Platform infrastructure.

### Task 1: Customize infrastructure components

You can define an az-hop environment by using a configuration file named **config.yml**, which needs to reside in the root of the repository. The simplest way to create the environment is to clone the template file **config.tpl.yml** and modify the content of the copied file. In this task, you will review its content and if needed, set the target Azure region for deploying the Azure HPC OnDemand Platform infrastructure.

1. For this lab, a simplied template is provided, but take some time to review the content of the configuration file content from the azhop [define the environment documentation page](https://azure.github.io/az-hop/deploy/define_environment.html)

1. On the lab computer, in the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following commands to download and copy **config.tpl.yml** to **config.yml**:

   ```bash
   wget https://raw.githubusercontent.com/azure/az-hop/main/tutorials/lab1/config.tpl.yml -O config.yml
   ```

1. Open the **config.yml** file using your preferred editor such as `nano` or `vi`:

   ```bash
   vi config.yml
   ```

1. Review the content of the **config.yml** file and note that it includes the following settings:

   - **location**: The name of the target Azure region.
   - **resource_group**: The name of the target resource group. You do have the option of using an existing resource group by setting **use_existing_rg** to **true**.
   - **anf**: Configuration properties of Azure NetApp Files resources.
   - **admin_user**: The name of the admin user account. Its random password is autogenerated and stored in the Azure Key vault provisioned as part of the deployment.
   - **network**: Configuration properties of the Azure virtual network into which the Azure resources hosting the infrastructure resources are deployed.
   - **jumpbox**, **ad**, **ondemand**, **grafana**, **guacamole**, **scheduler**, **cyclecloud** and **lustre**: Configuration properties of Azure VMs hosting the infrastructure components.
   - **users**: User accounts auto provisioned as part of the deployment.
   - **queue_manager**: The name of the scheduler to be installed and configured, which is **openpbs** by default.
   - **authentication**: The authentication method, which is **basic** by default. But you have the option of using **OpenID Connect** instead.
   - **images**: The list of images that will be available for deployment of compute cluster nodes and their respective configuration.
   - **queues**: The list of node arrays of CycleCloud and their respective configuration.

1. Change the name of the target Azure region set in the **config.yml** file to the one you are using in this lab, save the change, and then close the file.

### Task 2: Deploy Azure HPC OnDemand Platform infrastructure

1. Within the SSH session to the Azure VM, run the following command to generate a Terraform deployment plan that includes the listing of all resources to be provisioned:

   ```bash
   ./build.sh -a plan
   ```

1. Review the generated list of resources, and then run the following command to trigger the deployment of the Azure HPC OnDemand Platform infrastructure:

   ```bash
   ./build.sh -a apply
   ```

   > Note: Wait for the deployment to complete. This should take about 15 minutes. After the deployment completes, you should observe the message stating something similar to **Apply complete! Resources: 142 added, 0 changed, 0 destroyed.**


### Task 3: Build images

The az-hop solution provides pre-configured Packer configuration files that can be used to build custom images. The utility script **./packer/build_image.sh** performs the build process and stores the resulting images in the Shared Image Gallery included in the deployed infrastructure. Because building these images is a long process, we will use `screen` to build them in parallel.

1. On the lab computer, in the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following commands to build a custom image based on the **azhop-centos79-v2-rdma-gpgpu.json** configuration file.

   > Note: The image creation process based on the **azhop-centos79-v2-rdma-gpgpu.json** configuration file relies on a **Standard_d8s_v3** SKU Azure VM.

   ```bash
   screen -S packer1
   cd packer/
   ./build_image.sh -i azhop-centos79-v2-rdma-gpgpu.json
   ```

   > Note: Disregard any warning messages.

   > Note: Wait for the process to complete. This might take about 20 minutes.

   Detach from the current screen with `<ctrl>a+d`

1. Within the SSH session to the Azure VM, run the following command to build a custom image based on the **centos-7.8-desktop-3d.json** configuration file.

   > Note: The image creation process based on the **centos-7.8-desktop-3d.json** configuration file relies on a **Standard_NV12s_v3** SKU Azure VM, however this lab assume that you have quota only for **Standard_NV6**, you will have to update the **centos-7.8-desktop-3d.json** to use it as explained below.

   Open the **centos-7.8-desktop-3d.json**, update `vm_size` to **Standard_NV6** and delete the line containing **managed_image_storage_account_type**. The content should look like this
```json
   {
      "builders": [
         {
            "type": "azure-arm",
            "use_azure_cli_auth": "{{user `var_use_azure_cli_auth`}}",
            "image_publisher": "OpenLogic",
            "image_offer": "CentOS-HPC",
            "image_sku": "7_8",
            "image_version": "latest",
            "managed_image_resource_group_name": "{{user `var_resource_group`}}",
            "managed_image_name": "{{user `var_image`}}",
            "os_type": "Linux",
            "vm_size": "Standard_NV6",
            "ssh_pty": "true",
            "build_resource_group_name": "{{user `var_resource_group`}}",
            "private_virtual_network_with_public_ip": "{{user `var_private_virtual_network_with_public_ip`}}",
            "virtual_network_name": "{{user `var_virtual_network_name`}}",
            "virtual_network_subnet_name": "{{user `var_virtual_network_subnet_name`}}",
            "virtual_network_resource_group_name": "{{user `var_virtual_network_resource_group_name`}}",
            "cloud_environment_name": "{{user `var_cloud_env`}}",
            "ssh_bastion_host": "{{user `var_ssh_bastion_host`}}",
            "ssh_bastion_port": "{{user `var_ssh_bastion_port`}}",
            "ssh_bastion_username": "{{user `var_ssh_bastion_username`}}",
            "ssh_bastion_private_key_file": "{{user `var_ssh_bastion_private_key_file`}}"
        }
    ]
```
   ```bash
   screen -S packer2
   cd packer
   ./build_image.sh -i centos-7.8-desktop-3d.json
   ```

   > Note: Wait for the process to complete. This might take about 40 minutes.

   Detach from the current screen with `<ctrl>a+d`

1. Check the image build status by switching between `screen` sessions.

   - **\<ctrl> a+d** : to detach
   - **screen -ls** : to list sessions
   - **screen -r [name]**: to reattach to the session [name]

A typical output of a sucessful image build should end like this
```
Creating an image definition for azhop-centos79-v2-rdma-gpgpu
Read image definition from ../config.yml
/subscriptions/xxxxxx/resourceGroups/azhop-lab1/providers/Microsoft.Compute/galleries/azhop_ya3hzc6v/images/azhop-centos79-v2-rdma-gpgpu
Looking for image azhop-centos79-v2-rdma-gpgpu version  ...
Pushing version 7.9.220608174 of azhop-centos79-v2-rdma-gpgpu in azhop_ya3hzc6v
/subscriptions/xxxxx/resourceGroups/azhop-lab1/providers/Microsoft.Compute/galleries/azhop_ya3hzc6v/images/azhop-centos79-v2-rdma-gpgpu/versions/7.9.220608174e
astus   7.9.220608174   Succeeded    None    azhop-lab1    Microsoft.Compute/galleries/images/versions
Tagging the source image with version 7.9.220608174 and checksum b94b6fe74922717c402ed09e9675e3fe
None    V2    /subscriptions/xxxxxx/resourceGroups/azhop-lab1/providers/Microsoft.Compute/images/azhop-centos79-v2-rdma-gpgpu   eastus  azhop-centos79-v2-rdma
-gpgpu  Succeededazhop-lab1Microsoft.Compute/images
```
### Task 4: Review deployment results

1. On the lab computer, in the browser window displaying the Azure portal, open another tab, navigate to the Azure portal, use the **Search resources, services, and docs** text box to search for **Azure compute galleries**, and in the list of results, select **Azure compute galleries**.
1. On the **Azure compute galleries** blade, select the entry whose name starts with the prefix **azhop** and then on the compute gallery blade, verify that the gallery includes two VM image definitions.
1. In the Azure portal, use the **Search resources, services, and docs** text box to search for **Azure virtual machines**, and in the list of results, select **Virtual machines**.
1. On the **Virtual machines** blade, review the listing of the provisioned virtual machines.

   > Note: If needed, filter the listing of the virtual machines by setting the resource group criterion to **azhop**.

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

   > Note: Record the password. You will need it later in this lab.

   > Note: The **./bin/get_secret utility script** retrieves the password of the user you specify as its parameter from the Azure Key vault, which is part of the Azure HPC OnDemand Platform infrastructure you deployed in the previous exercise.

## Exercise 3: Install and configure Azure HPC OnDemand Platform software components

Duration: 50 minutes

In this exercise, you'll install and configure software components that form the Azure HPC OnDemand Platform solution.

> Note: You will perform this installation by using Ansible playbooks, which supports setup for individual components and an entire solution. In either case, its necessary to account for dependencies between components. The setup script **install.sh** in the root directory of the repository performs the installation in the intended order. The components include: **ad**, **linux**, **add_users**, **lustre**, **ccportal**, **cccluster** (this component requires that custom images are present in the compute gallery), **scheduler**, **ood**, **guacamole**, **guac_spooler**, **grafana**, **telegraf**, and **chrony**.

### Task 1: Install Azure HPC OnDemand Platform software components

1. On the lab computer, in the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following command to invoke the installation of the Azure HPC OnDemand Platform software components:

   ```bash
   ./install.sh
   ```

   > Note: Wait for the process to complete. This might take about 30 minutes.

   > Note: In case of a transient failure, you can rerun the install script can be rerun because most of the settings are idempotent. In addition, the script has a checkpointing mechanism that creates component-specific files with the **.ok** extension in the playbooks directory and checks for their presence during subsequent runs. If you want to reapply the configuration to an existing component, rerun the install script with one of component name listed above.

### Task 2: Review installation results

1. After the installation completes, on the lab computer, in the browser window displaying the Azure portal, within the SSH session to the Azure VM, run the following command to display the URL of the Azure HPC On-Demand Platform portal:

   ```bash
   grep ondemand_fqdn playbooks/group_vars/all.yml
   ```

   > Note: Record this value. You'll need it throughout the remainder of this lab.

1. From the lab computer, start a web browser, navigate to the URL of the Azure HPC On-Demand Platform portal you identified earlier in this task, and when prompted sign in with the **clusteradmin** user account and its password you identified in the previous step.

   > Note: You'll be presented with the **Azure HPC On-Demand Platform** dashboard. Review its interface, starting with the top-level menu, which provides access to **Apps**, **Files**, **Jobs**, **Clusters**, **Interactive Apps**, **Monitoring**, and **My Interactive Sessions** menu items.

1. In the **Monitoring** menu, select **Azure CycleCloud**.
1. When presented with the page titled **App has not been initialized or does not exist**, select **Initialize App**.

   > Note: This prompt reflects the OnDemand component architecture, which the Azure HPC OnDemand Platform solution relies on to implement its portal. The shared frontend creates Per User NGINX (PUN) processes to provide connectivity to such components as **Azure CycleCloud**, **Grafana**, or **Robinhood Dashboard**.

1. On the **Azure CycleCloud for Azure HPC On-Demand Platform** page, note the presence of a configuration of a cluster named **pbs1**.
1. On the **pbs1** page, select the **Arrays** tab, and note that it contains six entries representing queue definitions you reviewed earlier in the **config.yml** file.

## Exercise 6: Optionally - Deprovision Azure HPC OnDemand Platform environment

> Note: Do only this if you don't plan to run Lab 2

Duration: 5 minutes

In this exercise, you will deprovision the Azure HPC OnDemand Platform lab environment.

### Task 1: Deprovision the Azure resources

1. On the lab computer, switch to the browser window displaying the Azure portal
1. Remove the resource group you have choosen to deploy azhop in.

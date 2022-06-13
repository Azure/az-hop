<!-- TOC -->

- [Azure HPC OnDemand Platform lab guide](#azure-hpc-on-demand-platform-lab-guide)
  - [Excercise 1: Connect on the portal](#excercise-1-connect-on-the-portal)
    - [Task 1: Review installation results](#task-1-review-installation-results)
  - [Exercise 2: Review the main az-hop features](#exercise-2-review-the-main-az-hop-features)
    - [Task 1: Using file explorer](#task-1-using-file-explorer)
    - [Task 2: Using shell access](#task-2-using-shell-access)
    - [Task 3: Running interactive apps using Code Server and Linux Desktop](#task-3-running-interactive-apps-using-code-server-and-linux-desktop)
    - [Task 4: Running Intel MPI PingPong jobs from the Job composer](#task-4-running-intel-mpi-pingpong-jobs-from-the-job-composer)
    - [Task 5: Create jobs based on a non-default Azure HPC OnDemand Platform template](#task-5-create-jobs-based-on-a-non-default-azure-hpc-ondemand-platform-template)
  - [Exercise 3: Set up Spack](#exercise-3-set-up-spack)
    - [Task 1: Create a Code Server session](#task-1-create-a-code-server-session)
    - [Task 2: Install Spack](#task-2-install-spack)
  - [Exercise 6: Build and run OSU Benchmarks](#exercise-4-build-and-run-osu-benchmarks)
    - [Task 1: Build OSU Benchmarks with OpenMPI](#task-1-build-osu-benchmarks-with-openmpi)
    - [Task 2: Create the run script](#task-2-create-the-run-script)
    - [Task 3: Submit OSU jobs](#task-3-submit-osu-jobs)
  - [Exercise 5: Build, run, and analyze reservoir simulation using OPM Flow](#exercise-5-build-run-and-analyze-reservoir-simulation-using-opm-flow)
    - [Task 1: Build OPM](#task-1-build-opm)
    - [Task 2: Retrieve test data and run a flow job](#task-2-retrieve-test-data-and-run-a-flow-job)
    - [Task 3: View the results of the OPM job by using ResInsight](#task-3-review-the-results-of-the-opm-job-by-using-resinsight)
  - [Exercise 6: Build, run, and analyze OpenFOAM](#exercise-6-build-run-and-analyze-openfoam)
    - [Task 1: Build OpenFOAM](#task-1-build-openfoam)
    - [Task 2: Running the motorbike tutorial on a single node](#task-2-running-the-motorbike-tutorial-on-a-single-node)
    - [Task 3: Running the motorbike tutorial on multiple nodes](#task-3-running-the-motorbike-tutorial-on-multiple-nodes)
    - [Task 4: Visualize the motorbike tutorial result](#task-4-visualize-the-motorbike-tutorial-result)
  - [Exercise 7: Deprovision Azure HPC OnDemand Platform environment](#exercise-7-deprovision-azure-hpc-ondemand-platform-environment)
    - [Task 1: Deprovision the Azure resources](#task-1-deprovision-the-azure-resources)

<!-- /TOC -->

# Azure HPC OnDemand Platform lab guide

This lab assume that you have successfully completed [Implementing Azure HPC OnDemand Platform Lab 1](Implementing_Azure_HPC_OnDemand_Platform_Lab_1.md).
## Excercise 1: Connect on the portal
### Task 1: Review installation results

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

## Exercise 2: Review the main az-hop features

Duration: 60 minutes

In this exercise, you will review the main features of the Azure HPC OnDemand Platform lab environment.

### Task 1: Using file explorer

> Note: For more information regarding this topic, refer to [https://azure.github.io/az-hop/user_guide/files.html](https://azure.github.io/az-hop/user_guide/files.html)

> Note: You can access your home directory files directly from the OnDemand interface.

1. On the lab computer, in the browser window, in the **Azure HPC On-Demand Platform** portal, select the **Files** menu. Then, from the drop-down menu, select **Home Directory**.
1. On the **Home Directory** page, review its interface, including the options to:

   - Create directories and files.
   - Upload and download files.
   - Perform copy and move operations.
   - Delete directories and files.
   - Open the terminal window in the current file system location.

### Task 2: Using shell access

> Note: For more information regarding this topic, refer to [https://azure.github.io/az-hop/user_guide/clusters.html](https://azure.github.io/az-hop/user_guide/clusters.html)

1. In the **Azure HPC On-Demand Platform** portal, select the **Clusters** menu, and then from the drop-down menu, select **AZHOP - Cluster Shell Access**.

   > Note: This will open another browser tab displaying a shell session to the cluster.

1. In the shell session, run the following command to submit a simple test job:

   ```bash
   qsub -l select=1:slot_type=execute -- /usr/bin/bash -c 'sleep 60'
   ```

   > Note: Do not paste commands into the shell session pane, enter them instead.

1. In the shell session, run the following command to display the status of the submitted job:

   ```bash
   [clusteradmin@ondemand ~]$ qstat -anw1
   scheduler: 
                                                                                                      Req'd  Req'd   Elap
   Job ID                         Username        Queue           Jobname         SessID   NDS  TSK   Memory Time  S Time
   ------------------------------ --------------- --------------- --------------- -------- ---- ----- ------ ----- - -----
   0.scheduler                    clusteradmin    workq           STDIN                --     1     1    --    --  Q  --   -- 
   [clusteradmin@ondemand ~]$
   ```

   > Note: Examine the output of the command and verify that the submitted job is in the queue.

1. Switch to the browser tab with the **Azure CycleCloud for Azure HPC On-Demand Platform** page. After some time (less than a minute), a new **execute** instance is created.
1. Review the newly created job's progress, including the new VM creation.

### Task 3: Running interactive apps using Code Server and Linux Desktop

> Note: For more information regarding this topic, refer to [https://azure.github.io/az-hop/user_guide/code_server.html](https://azure.github.io/az-hop/user_guide/code_server.html) and [https://azure.github.io/az-hop/user_guide/remote_desktop.html](https://azure.github.io/az-hop/user_guide/remote_desktop.html)

1. On the lab computer, in the browser window, switch to the tab displaying the **Azure HPC On-Demand Platform** portal.
1. Select the **Interactive Apps** menu, and then from the drop-down menu, select **Code Server**.

   > Note: This will open another browser tab displaying the **Code Server** launching page.

1. On the **Code Server** launching page, in the **Maximum duration of your remote session** field, enter **1**. In the **Slot Type** text box, enter **execute**, and then select **Launch**.

   > Note: This will initiate the provisioning of a compute node of the type you specified. Note that this creates a new job and the **Queued** status for this job is displayed on the same page.

1. Switch to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the **execute** node provisioning's progress.

   > Note: Wait until the node status changes to **Ready**. This should take about 5 minutes.

1. Switch back to the **Code Server** launching page.
1. Verify that the corresponding job's status has changed to **Running**, and then select **Connect to VS Code**.

   > Note: This will open another browser tab displaying the Code Server interface.

1. Review the interface, and then close the **Welcome** tab.
1. In the top left corner of the page, select the **Application** menu. From the drop-down menu, select **Terminal**, and then in the cascading menu, select **New Terminal**.
1. In the **Terminal** pane, at the **[clusteradmin@execute-1 ~]$** prompt, enter `qstat` to observe the currently running job.
1. You can now edit any files located in your home directory, git clone repos and connect to your github account.
1. Switch back to the **Azure HPC On-Demand Platform** home page, or the `Dashboard`.
1. Select **Linux Desktop**.
1. On the **Linux Desktop** launching page, from the **Session target** drop-down list, ensure that **With GPU - Small GPU node for single session** is selected.
1. In the **Maximum duration of your remote session** field, enter **1**
1. In the **Maximum number of cores of your session** field, enter **0**
1. Select **Launch**.

   > Note: This will begin compute node provisioning of the type you specified. This also creates a new job with its **Queued** status displaying on the same page.

1. Switch back to the **Linux Desktop** launching page.
1. From the **Session target** drop-down list, select **Without GPU - for single session**.
1. In the **Maximum duration of your remote session** field, enter **1**
1. In the **Maximum number of cores of your session** field, enter **0**
1. Select **Launch**.

   > Note: The ability to extend the time you specify is not supported. After the time you specified passes, the session terminates. However, you can choose to terminate the session early.

   > Note: This will initiate the provisioning of a compute node of the type you specified. Note that this creates a new job and the **Queued** status for this job is displayed on the same page.

1. Switch to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the progress of the **viz** and **viz3d** node provisioning.

   > Note: Wait until the status of the node changes to **Ready**. This should take about 10 minutes.

   > Note: The **viz3d** node provisioning will fail if your subscription doesn't offer **Standard_NV6** SKU in the Azure region hosting your az-hop deployment.

1. Switch back to the **My Interactive Sessions** page, and then verify that the corresponding job's status has changed to **Running**.
1. Use the **Delete** button to delete the **Code Server** job by selecting **Confirm** when prompted.
1. On the session with hosts named `viz3d-1`, adjust **Compression** and **Image quality** according to your preferences, and then select **Launch Linux Desktop**.

   > Note: This will open another browser tab displaying the Linux Desktop VNC session.

1. Open a terminal and run `nvidia-smi` to validate that GPU is enabled
1. In the open terminal run `glxspheres64` and observed the performances. This is running witout GPU acceleration and should deliver about **40 frames/sec**.
1. Close the **GLX Spheres** window and rerun it by prefexing the command with vglrun to offload Opengl to the GPU: `vglrun glxspheres64`. Performances should be increased to about **400 frames/sec** depending on your screen size, quality and compression options.
1. Start a new terminal and launch `nvidia-smi` to check the GPU usage which should be aboud **35%**.

> Note: The `vglrun` command can be called for all applications which use Opengl to offload calls to the GPU.

1. Switch back to the **My Interactive Sessions** launching page and use the **Delete** button to delete the **Linux Desktop** jobs by selecting **Confirm** when prompted.

### Task 4: Running Intel MPI PingPong jobs from the Job composer

1. On the lab computer, in the browser window displaying the Azure HPC On-Demand Platform portal, navigate to the **Dashboard** page.
On the **Dashboard** page, select the **Jobs** menu title, and from the drop-down menu, select **Job Composer**.
1. On the **Jobs** page, select **+ New job**, and from the drop-down menu, select **From Default Template**.

   > Note: This will automatically create a job named **(default) Sample Sequential Job** that targets the **execute** CycleCloud array. To identify the content of the job script, ensure that the newly created job is selected, and then review the **Script contents** pane.

1. Repeat the previous step twice to create two additional jobs based on the default template.

   > Note: The default job template contains a trivial script that runs `echo "Hello World"`.

1. Note that all three jobs are currently in the **Not Submitted** state. To submit them, select each one of them, and then select **Submit**.

   > Note: The status of the jobs should change to **Queued**.

1. On the lab computer, in the browser window displaying the Azure HPC On-Demand Platform portal, select the **Azure HPC On-Demand Platform** header. Select the **Monitoring** menu, and from the drop-down list, select **Azure CycleCloud**.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, monitor the status of the cluster and note that the number of nodes increases to **3**, which initially are listed in the **acquiring** state. This can takes a minute to come.
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

   > Note: Wait until the status of nodes changes to **Ready**. This should take about 5 minutes.

1. After the nodes' status changes to **Ready**, switch to the **Active jobs** page.
1. Refresh the **Active jobs** page and note that the jobs are no longer listed.

   > Note: If the jobs are still listed as **Queued**, wait for a few more minutes, and then refresh the page again.
1. Navigate back to the **Job Composer** page, and note that all jobs are now completed.
1. Select one of the completed job, and in the right panel, under **Folder Contents** click on the **STDIN.o??** file to look at it's content.

1. Navigate back to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the node status until it changes to terminating, which will result eventually in their deletion. This should be done after about 15 to 20mn of idle time.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, on the **pbs1** page, select the **Scalesets** tab.
1. Note that the scaleset hosting the cluster nodes persists but its size is set to **0**.

### Task 5: Create jobs based on a non-default Azure HPC OnDemand Platform template

1. On the lab computer, in the browser window, switch back to the **Azure HPC On-Demand Platform** portal.
1. Select the **Jobs** menu, and from the drop-down menu, select **Job Composer**.
1. On the **Jobs** page, select **Templates**.
1. On the **Templates** page, in the list of predefined templates, select the **Intel MPI PingPong** entry, and then select **Create New Job**.

   > Note: The Message Passing Interface (MPI) ping-pong tests measure network latency and throughput between nodes in the cluster by sending packets of data back and forth between paired nodes repeatedly. The *latency* is the average of half of the time that it takes for a packet to make a round trip between a pair of nodes, in microseconds. The *throughput* is the average rate of data transfer between a pair of nodes, in MB/second.

   > Note: This will automatically create a job named **Intel MPI PingPong** that targets the **hb120v3** slot_type, as this lab is setup for **hb120v2** you will have to update the job file.
1. In the **Submit Script** from the right panel, click on the button **Open Editor** at the bottom. This will open a new tab with the pingpong script open.
1. On line 3, change **hb120v3** to **hb120v2**. Click on the **Save** button and close the tab.

1. Create two additional jobs based on the **Intel MPI PingPong** job by expanding the **+ New Job** button and chosing the **From Selected Job**.
1. Note that, as before, all three jobs are currently in the **Not Submitted** state. To submit them, select each one of them, and then select **Submit**.

   > Note: The status of the jobs should change to **Queued**.

1. Navigate to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the node provisioning progress.

   > Note: Wait until the nodes' status changes to **Ready**. This should take about 10 minutes.

   > Note: Despite asking for 3 jobs with 2 nodes each, only 4 machines are provisioned, this is because the configuration has been set to a maximum of 4 machines for this environment.

1. After the node status changes to **Ready**, switch back to the **Active jobs** page, and then refresh it. Note that the jobs are no longer listed.

   > Note: If the jobs are still listed as **Queued**, wait for a few more minutes, and then refresh the page again.

1. Navigate to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the node status until it changes to terminating, resulting eventually in their deletion.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, on the **pbs1** page, select the **Scalesets** tab.
1. Note that the scaleset hosting the cluster nodes persists but its size is set to **0**.
1. To review the job output, switch to the **Azure HPC On-Demand Platform** portal, select the **Jobs** menu, and then from the drop-down menu, select **Job Composer**.
1. On the **Jobs** page, select any of the **Intel MPI PingPong** job entries, and in the **Folder Contents** section, select **PingPong.o??**.

   > Note: This will automatically open another web browser tab displaying the output of the job.

## Exercise 3: Set up Spack

Duration: 30 minutes

In this exercise, you will install and configure Spack from Code Server, as documented in [https://azure.github.io/az-hop/tutorials/spack.html](https://azure.github.io/az-hop/tutorials/spack.html).

### Task 1: Create a Code Server session

1. On the lab computer, in the browser window, switch to the tab displaying the **Azure HPC On-Demand Platform** portal.
1. Select the **Interactive Apps** menu, and from the drop-down menu, select **Code Server**.

   > Note: This will open another browser tab displaying the **Code Server** launching page.

1. On the **Code Server** launching page, in the **Maximum duration of your remote session** field, enter **3**. In the **Slot Type** text box, enter **hb120v2**, and then select **Launch**.

   > Note: This will initiate the provisioning of a compute node of the type you specified. Note that this creates a new job and the **Queued** status for this job is displayed on the same page.

1. Switch to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the progress of the **hb120v2** node provisioning.

   > Note: Wait until the node status changes to **Ready**. This should take about 5 minutes.

1. Switch back to the **Code Server** launching page, verify that the corresponding job's status has changed to **Running**, and then select **Connect to VS Code**.

   > Note: This will open another browser tab displaying the Code Server interface.

1. Review the interface, and then close the **Welcome** tab.
1. Select the **Application** menu, from the drop-down menu select **Terminal**, and then from the sub-menu that opens, select **New Terminal**.
1. In the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$** prompt, run the following command to clone the azurehpc repo and use the azhop/spack branch:

   ```bash
   git clone https://github.com/Azure/azurehpc.git
   ```

### Task 2: Install Spack

1. In the **Terminal** pane, review and run the following scripts to install and configure Spack:

   ```bash
   ~/azurehpc/experimental/azhop/spack/install.sh
   ~/azurehpc/experimental/azhop/spack/configure.sh
   ```

   > Note: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v2-1 ~]$ ~/azurehpc/experimental/azhop/spack/install.sh
   Cloning into '/anfhome/clusteradmin/spack'...
   remote: Enumerating objects: 389726, done.
   remote: Counting objects: 100% (18/18), done.
   remote: Compressing objects: 100% (17/17), done.
   remote: Total 389726 (delta 1), reused 9 (delta 0), pack-reused 389708
   Receiving objects: 100% (389726/389726), 173.48 MiB | 48.70 MiB/s, done.
   Resolving deltas: 100% (167923/167923), done.
   Checking out files: 100% (9513/9513), done.
   Checking out files: 100% (6826/6826), done.
   Branch releases/v0.18 set up to track remote branch releases/v0.18 from origin.
   Switched to a new branch 'releases/v0.18'
   [clusteradmin@hb120v2-1 ~]$ ~/azurehpc/experimental/azhop/spack/configure.sh
   Add GCC compiler
   ==> Added 1 new compiler to /anfhome/clusteradmin/.spack/linux/compilers.yaml
       gcc@9.2.0
   ==> Compilers are defined in the following files:
       /anfhome/clusteradmin/.spack/linux/compilers.yaml
   Configure external MPI packages
   Configure local settings
   ```

1. Run the following commands to confirm the list of defined compilers:

   ```bash
   . ~/spack/share/spack/setup-env.sh
   spack compilers
   ```

   > Note: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v2-1 ~]$
   [clusteradmin@hb120v2-1 ~]$ spack compilers
   ==> Available compilers
   -- gcc centos7-x86_64 -------------------------------------------
   gcc@9.2.0
   ```

   > Note: Verify that gcc 9.2 is referenced in the output.

## Exercise 4: Build and run OSU Benchmarks
In this exercise, you will build and run some of the OSU Benchmarks used to measure latency and bandwith using OpenMPI.

Duration: 30 minutes
### Task 1: Build OSU Benchmarks with OpenMPI
1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following command to load Spack modules:

   ```bash
   . ~/spack/share/spack/setup-env.sh
   module use /usr/share/Modules/modulefiles
   ```
1. Install OSU benchmarks with Spack and OpenMPI
   ```bash
   spack install osu-micro-benchmarks^openmpi
   ```

### Task 2: Create the run script

1. At the root of the home directory, create a file named **osu_benchmarks.sh** with this content
```bash
#!/bin/bash
BENCH=${1:-osu_latency}
. ~/spack/share/spack/setup-env.sh
source /etc/profile.d/modules.sh
module use /usr/share/Modules/modulefiles
spack load osu-micro-benchmarks^openmpi
mpirun -x PATH --hostfile $PBS_NODEFILE --map-by ppr:1:node --bind-to core --report-bindings $BENCH
```

1. Enable execution for this script
```bash
chmod +x ~/osu_benchmarks.sh
```

### Task 3: Submit OSU jobs
1. Submit a first job for running the bandwidth benchmarks. Note the **slot_type** used in the select statement.
```bash
qsub -N BW -joe -koe -l select=2:slot_type=hb120v2 -- osu_benchmarks.sh osu_bw
```

1. And a second one for the latency test
```bash
qsub -N LAT -joe -koe -l select=2:slot_type=hb120v2 -- osu_benchmarks.sh osu_latency
```

2. Review the results of the jobs in files names **LAT.o??** and **BW.o??** at the root of the home directory

> Note : At this point you can do Exercise 5 and/or 6 either in parallel or any of the two.
## Exercise 5: Build, run, and analyze reservoir simulation using OPM Flow

In this exercise, you will build, run, and analyze reservoir simulation using OPM (Open Porous Media) Flow.

Duration: 60 minutes

### Task 1: Build OPM

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following command to load Spack modules:

   ```bash
   module use /usr/share/Modules/modulefiles
   ```

1. Review the following script and run it to create the az-hop Spack repo:

   ```bash
   . ~/spack/share/spack/setup-env.sh
   ~/azurehpc/experimental/azhop/azhop-spack/install.sh
   ```

   > Note: The output should resemble the following listing:

   ```bash
   ==> Added repo with namespace 'azhop'.
   ```

1. Review the following script and run it to configure the OPM packages:

   ```bash
   ~/azurehpc/experimental/azhop/opm/configure.sh
   ```

   > Note: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v2-1 ~]$ ~/azurehpc/experimental/azhop/opm/configure.sh
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

   > Note: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v2-1 ~]$ module avail

      --------------------------------------------------------------------------------------------- /usr/share/Modules/modulefiles ---------------------------------------------------------------------------------------------
      amd/aocl            dot                 module-git          modules             mpi/hpcx-v2.9.0     mpi/impi_2018.4.274 mpi/impi_2021.4.0   mpi/mvapich2-2.3.6  mpi/openmpi-4.1.1   use.own
      amd/aocl-2.2-4      gcc-9.2.0           module-info         mpi/hpcx            mpi/impi            mpi/impi-2021       mpi/mvapich2        mpi/openmpi         null
   ```

   > Note: Review the output and note the openmpi version.

1. Use your preferred text editor to update the **~/.spack/packages.yaml** file content by replacing references to **hpcx** with **openmpi**, removing **hpcx**-related entries, and if necessary, updating the openmpi version to the one you identified in the previous step.

   > Note: The following example is sample content from the **~/.spack/packages.yaml** file:

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

   > Note: You must use the following updated content with openmpi version 4.1.1.

   ```bash
   packages:
     all:
       target: [x86_64]
       providers: 
         mpi: [openpmi]
     openmpi:
       externals:
       - spec: openmpi@4.1.1%gcc@9.2.0
         modules:
         - mpi/openmpi-4.1.1
       buildable: False
   ```

1. Review the following script and run it to build OPM:

   ```bash
   ~/azurehpc/experimental/azhop/opm/build.sh
   ```

   > Note: The output should start with the following listing:

   ```bash
   [clusteradmin@hb120v2-1 ~]$ ~/azurehpc/experimental/azhop/opm/build.sh
   ==> Warning: Missing a source id for openmpi@4.1.1
   ==> Warning: Missing a source id for dune@2.7
   ==> Installing pkg-config-0.29.2-opt4cajmlefjsbaqmhcuxegkkdr6gvac
   ==> No binary for pkg-config-0.29.2-opt4cajmlefjsbaqmhcuxegkkdr6gvac found: installing from source
   ==> Fetching https://mirror.spack.io/_source-cache/archive/6f/6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591.tar.gz
   ######################################################################## 100.0%
   ==> pkg-config: Executing phase: 'autoreconf'
   ==> pkg-config: Executing phase: 'configure'
   ```

   > Note: Wait for the build to complete. This might take about 40 minutes.

### Task 2: Retrieve test data and run a flow job

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$** prompt, run the following commands to download test data:

   ```bash
   cd /lustre
   mkdir $USER
   cd $USER
   git clone https://github.com/OPM/opm-data.git
   ```

1. Run the following command to copy the **~/azurehpc/experimental/azhop/opm/run_opm.sh** file to the home directory:

   ```bash
   cp ~/azurehpc/experimental/azhop/opm/run_opm.sh ~
   ```

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$** prompt, open the newly created copy of the **run_opm.sh** file in a text editor.
1. Make the following changes to the file, and close it after saving the changes:

   - Modify the input file path (`INPUT`) by replacing the entry `~/opm-data/norne` with `/lustre/$USER/opm-data/norne`).
   - Modify the compute node configuration by replacing the entry `select=1:ncpus=40:mpiprocs=40:slot_type=hc44rs` with `select=1:ncpus=120:mpiprocs=60:slot_type=hb120v2`.
   - Add the `which flow` line following the `spack load opm-simulators` line.

   > Note: Leave the number of nodes set to **1** to avoid the quota limit issues.

   > Note: The original **run_opm.sh** file has the following content:

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

   > Note: The modified **run_opm.sh** file should have the following content:

   ```bash
   #!/bin/bash
   #PBS -N OPM
   #PBS -l select=1:ncpus=120:mpiprocs=60:slot_type=hb120v2
   #PBS -k oed
   #PBS -j oe
   #PBS -l walltime=3600

   INPUT=/lustre/$USER/opm-data/norne/NORNE_ATW2013.DATA
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

1. On the lab computer, in the browser window displaying the Code Server, in the Terminal pane, from the prompt **[clusteradmin@hb120v2-1 ~]$**, run the following command to submit the job referenced in the **~/run_opm.sh** file:

   ```bash
   qsub ~/run_opm.sh 
   ```

1. Run the following command to verify that the job has been queued:

   ```bash
   qstat
   ```

   > Note: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v2-1 clusteradmin]$ qsub ~/run_opm.sh
   8.scheduler
   [clusteradmin@hb120v2-1 clusteradmin]$ qstat
   Job id            Name             User              Time Use S Queue
   ----------------  ---------------- ----------------  -------- - -----
   6.scheduler       sys-dashboard-s  clusteradmin      00:00:17 R workq           
   7.scheduler       STDIN            clusteradmin      03:24:08 R workq           
   8.scheduler       OPM              clusteradmin             0 Q workq  
   ```

   > Note: Review the output to identify the job name.

1. In the previous command's output, identify the **Job id** of the newly submitted job.
1. Run the following command to display the newly submitted job's status by replacing the `<jobid>` placeholder in the following command with the value you identified:

   ```bash
   qstat -fx <jobid>
   ```

   > Note: The output should start with the following listing:

   ```bash
   [clusteradmin@hb120v2-1 clusteradmin]$ qstat -fx 8.scheduler
   Job Id: 8.scheduler
       Job_Name = OPM
       Job_Owner = clusteradmin@hb120v2-1.internal.cloudapp.net
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
       Error_Path = hb120v2-1.internal.cloudapp.net:/lustre/clusteradmin/OPM.e8
       exec_host = hb120v2-2/0*120
       exec_vnode = (hb120v2-2:ncpus=120)
       Hold_Types = n
       Join_Path = oe
       Keep_Files = oed
       Mail_Points = a
       mtime = Tue Feb 22 18:36:42 2022
       Output_Path = hb120v2-1.internal.cloudapp.net:/lustre/clusteradmin/OPM.o8
       Priority = 0
       qtime = Tue Feb 22 18:26:47 2022
       Rerunable = True
       Resource_List.mpiprocs = 60
       Resource_List.ncpus = 120
       Resource_List.nodect = 1
       Resource_List.place = scatter:excl
       Resource_List.select = 1:ncpus=120:mpiprocs=60:slot_type=hb120v2
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
           PBS_O_QUEUE=workq,PBS_O_HOST=hb120v2-1.internal.cloudapp.net
       comment = Not Running: Not enough free nodes available
       etime = Tue Feb 22 18:26:47 2022
       run_count = 1
       Stageout_status = 1
       Exit_status = 0
       Submit_arguments = /anfhome/clusteradmin/run_opm.sh
       history_timestamp = 1645555002
       project = _pbs_project_default
   ```

   > Note: Wait for the job to complete. This might take about 5 minutes.

   > Note: To verify that the job completed, you can rerun the `qstat` command or the `qstat -fx <jobid>` command. The second command should display the comment in the format `comment = Job run at Tue Feb 22 at 18:40 on (hb120v2-2:ncpus=120) and finished`.

1. Run the following command to verify that the job has generated the expected output:

   ```bash
   ls /lustre/clusteradmin/opm-data/norne/out_parallel/
   ```

   > Note: Alternatively, you can review the corresponding job-related `~/OPM.*` file content.

   > Note: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v2-1 clusteradmin]$ ls /lustre/$USER/opm-data/norne/out_parallel/
   NORNE_ATW2013.EGRID     NORNE_ATW2013.INIT  NORNE_ATW2013.SMSPEC  NORNE_ATW2013.UNSMRY
   NORNE_ATW2013.INFOSTEP  NORNE_ATW2013.RFT   NORNE_ATW2013.UNRST
   ```

### Task 3: Review the results of the OPM job by using ResInsight

1. On the lab computer, in the browser window, switch back to the **Azure HPC On-Demand Platform** portal, and then in the **Interactive Apps** section, select **Linux Desktop**.
1. On the **Linux Desktop** launching page, from the **Session target** drop-down list, ensure that **With GPU** entry is selected. In the **Maximum duration of your remote session** field, enter **2**,  and then select **Launch**.

   > Note: In case your subscription doesn't have a sufficient number of quotas for the **Standard_NV6** SKU, choose the **Without GPU** entry instead.

   > Note: This will begin compute node provisioning of the type you specified. This also creates a new job with its **Queued** status displaying on the same page.

1. Switch back to the **Linux Desktop** launching page, and then verify that the corresponding job's status has changed to **Running**.
1. Adjust **Compression** and **Image quality** according to your preferences, and then select **Launch Linux Desktop**.

   > Note: This will open another browser tab displaying the Linux Desktop session.

1. Within the Linux Desktop session, start **Terminal Emulator**.

1. In the **Terminal Emulator** window, at the **[clusteradmin@vis-1 ~]$** prompt, run the following command to launch ResInsight:

   ```bash
   vglrun ResInsight
   ```

   > Note: This will open the ResInsight application window.

   > Note: If you're using a non-GPU VM SKU, rather than running `vglrun ResInsight, you'll need to launch ResInsight directly. To do this, in the **Linux Desktop** session, select **Application Finder** (the magnifying glass icon at the bottom, center section of the page). In the search text box, enter **ResInsight**. From the list of search results, select **ResInsight**, and then select **Launch**.

1. In the ResInsight application window, select the **File** menu header. From the drop-down menu, select **Import**, in the sub-menu, select **Eclipse cases**, and then select **Import Eclipse cases**.
1. In the **Import Eclipse File** dialog box, select **Computer**.
1. Navigate to **/lustre/clusteradmin/opm-data/norne/out_parallel**, and then from the list of files in the target directory, select **NORNE_ATW2013.EGRID**.
1. Review the case in the ResInsight application window.
1. Change the **Navigation Mode** to `Ceetron` in the 3d Views by opening the **Edit/Preferences** menu.
   - Rotation can be maintaining with the right mouse button
1. In the button ribbon, play the simulation with the **>** button.

## Exercise 6: Build, run, and analyze OpenFOAM

In this exercise, you will build, run, and analyze CFD simulation using OpenFOAM.

Duration: 60 minutes

### Task 1: Build OpenFOAM

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following command to build OpenFOAM 8:

   ```bash
   . ~/spack/share/spack/setup-env.sh
   module use /usr/share/Modules/modulefiles
   spack install openfoam-org@8
   ```
   > Note: Wait for the build to complete. This might take about 30 minutes.
### Task 2: Running the motorbike tutorial on a single node

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following command to load OpenFOAM modules:
   ```bash
   spack load openfoam-org@8
   ```

1. Copy the motorbike tutorial into scratch space
   ```bash
   mkdir -p /lustre/$USER
   cd /lustre/$USER
   cp -r $WM_PROJECT_DIR/tutorials/incompressible/simpleFoam/motorBike .
   ```

1. Run the case
   ```bash
   cd motorBike
   ./Allrun
   ```

1. Review all log files `log.*` for any errors

### Task 3: Running the motorbike tutorial on multiple nodes

The following updates are needed:

- Add FOAM_MPIRUN_FLAGS to the mpirun command when using runParallel (needed for all version of OpenFOAM)
- Reconstruct the single partition after the solve

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following commands:

   ```bash
      cd /lustre/$USER/motorBike
      sed -i '/RunFunctions/a source <(declare -f runParallel | sed "s/mpirun/mpirun \\\$FOAM_MPIRUN_FLAGS/g")' Allrun
      sed -i 's#/bin/sh#/bin/bash#g' Allrun
      sed -i 's/# runApplication reconstructPar/runApplication reconstructPar/g' Allrun
   ```

1. Now, create a PBS submit script, **submit.sh** withe the following content.

When running on multiple nodes it is necessary to export all the OpenFOAM environment variables (unless you add loading the modules in `.bashrc`). This is done with the `FOAM_MPIRUN_FLAGS` that are added to the `runParallel` in the last step. The script will run for the number of cores specified to PBS (`select` x `mpiprocs`)

```bash
#!/bin/bash
. ~/spack/share/spack/setup-env.sh
module use /usr/share/Modules/modulefiles
spack load openfoam-org@8
ranks_per_numa=4
export FOAM_MPIRUN_FLAGS="-hostfile $PBS_NODEFILE $(env |grep 'WM_\|FOAM' | cut -d'=' -f1 | sed 's/^/-x /g' | tr '\n' ' ') -x MPI_BUFFER_SIZE --report-bindings --map-by ppr:${ranks_per_numa}:numa"
$PBS_O_WORKDIR/Allrun -cores $(wc -l <$PBS_NODEFILE)
```

1. Save that file under the `/lustre/$USER/motorBike` directory

1. Run the OpenFOAM job

```bash
rm log.*
qsub -l select=2:slot_type=hb120v2:ncpus=120:mpiprocs=120,place=scatter:excl submit.sh
```

1. Monitor the job and wait for the job to be finished

### Task 4: Visualize the motorbike tutorial result

1. On the lab computer, in the browser window, switch back to the **Azure HPC On-Demand Platform** portal, and then in the **Interactive Apps** section, select **Linux Desktop**.
1. On the **Linux Desktop** launching page, from the **Session target** drop-down list, ensure that **With GPU** entry is selected. In the **Maximum duration of your remote session** field, enter **2**,  and then select **Launch**.

   > Note: In case your subscription doesn't have a sufficient number of quotas for the **Standard_NV6** SKU, choose the **Without GPU** entry instead.

   > Note: This will begin compute node provisioning of the type you specified. This also creates a new job with its **Queued** status displaying on the same page.

1. Switch back to the **Linux Desktop** launching page, and then verify that the corresponding job's status has changed to **Running**.
1. Adjust **Compression** and **Image quality** according to your preferences, and then select **Launch Linux Desktop**.

   > Note: This will open another browser tab displaying the Linux Desktop session.

1. Within the Linux Desktop session, start **Terminal Emulator**.

1. Install the **Paraview** viewer

```bash
wget "https://www.paraview.org/paraview-downloads/download.php?submit=Download&version=v5.10&type=binary&os=Linux&downloadFile=ParaView-5.10.1-MPI-Linux-Python3.9-x86_64.tar.gz" -O ParaView-5.10.1-MPI-Linux-Python3.9-x86_64.tar.gz

tar xvf ParaView-5.10.1-MPI-Linux-Python3.9-x86_64.tar.gz

```

1. Create a case file and launch Paraview

```bash
touch /lustre/$USER/motorBike/case.foam
vglrun ./ParaView-5.10.1-MPI-Linux-Python3.9-x86_64/bin/paraview
```

1. Open the model

Within **Paraview** open the case `/lustre/$USER/motorBike/case.foam`

When the model is loaded, you can view the geometry like this:
- In the bottom left pane, in the "Mesh Regions" list, unselect "internalMesh" and select "group/motorBikeGroup".
- Click "Apply" above the list.
- You should now see the model geometry, and you can move/rotate/zoom using the mouse.

Next, you can visualize the simulation results.
- Click the "Play" button on the toolbar at the top of the window to advance to the end of the simulation.
- On the Active Variables Coontrol toolbar you will find a drop down box where you can select variables. For example, select "p" for pressure.


## Exercise 7: Deprovision Azure HPC OnDemand Platform environment

Duration: 5 minutes

In this exercise, you will deprovision the Azure HPC OnDemand Platform lab environment.

### Task 1: Deprovision the Azure resources

1. On the lab computer, switch to the browser window displaying the Azure portal
1. Remove the resource group you have choosen to deploy azhop in.

<!--ts-->
* [Quickstart guide](#quickstart-guide)
   * [Requirements](#requirements)
   * [Exercise 1: Review the main az-hop features](#exercise-1-review-the-main-az-hop-features)
      * [Task 1: Using file explorer](#task-1-using-file-explorer)
      * [Task 2: Using shell access](#task-2-using-shell-access)
      * [Task 3: Hello World job](#task-3-hello-world-job)
      * [Task 4: Running Intel MPI PingPong jobs from the Job composer](#task-4-running-intel-mpi-pingpong-jobs-from-the-job-composer)
      * [Task 5: Running interactive apps using Code Server and Linux Desktop](#task-5-running-interactive-apps-using-code-server-and-linux-desktop)
   * [Exercise 2: Set up Spack](#exercise-2-set-up-spack)
      * [Task 1: Create a Code Server session](#task-1-create-a-code-server-session)
      * [Task 2: Install Spack](#task-2-install-spack)
   * [Exercise 3: Build and run OSU Benchmarks](#exercise-3-build-and-run-osu-benchmarks)
      * [Task 1: Build OSU Benchmarks with OpenMPI](#task-1-build-osu-benchmarks-with-openmpi)
      * [Task 2: Create the run script](#task-2-create-the-run-script)
      * [Task 3: Submit OSU jobs](#task-3-submit-osu-jobs)
   * [Exercise 4: Build, run, and analyze OpenFOAM](#exercise-4-build-run-and-analyze-openfoam)
      * [Task 1: Build OpenFOAM](#task-1-build-openfoam)
      * [Task 2: Running the motorbike tutorial on a single node](#task-2-running-the-motorbike-tutorial-on-a-single-node)
      * [Task 3: Running the motorbike tutorial on multiple nodes](#task-3-running-the-motorbike-tutorial-on-multiple-nodes)
      * [Task 4: Visualize the motorbike tutorial result](#task-4-visualize-the-motorbike-tutorial-result)
   * [Exercise 5: Run OpenFOAM DrivAer-Fastback simulation using EESSI stack](#exercise-5-run-openfoam-drivaer-fastback-simulation-using-eessi-stack)
      * [Task 1: Prepare the DrivAer-Fastback example](#task-1-prepare-the-drivaer-fastback-example)
      * [Task 2: Submit PBS job](#task-2-submit-pbs-job)
      * [Task 3: Create Linux Desktop session for visualization](#task-3-create-linux-desktop-session-for-visualization)
      * [Task 4: Visualize the DrivAer-Fastback simulation results](#task-4-visualize-the-drivaer-fastback-simulation-results)
   * [Exercise 6: Deprovision Azure HPC OnDemand Platform environment](#exercise-6-deprovision-azure-hpc-ondemand-platform-environment)
      * [Task 1: Deprovision the Azure resources](#task-1-deprovision-the-azure-resources)
<!--te-->
<!-- https://github.com/ekalinin/github-markdown-toc -->
<!-- ./gh-md-toc --insert --no-backup --hide-footer -->

# Quickstart guide
This QuickStart guide will show you how to build and use an OnDemand HPC cluster on Azure through the deployment of a simple **Azure HPC On-Demand Platform** environment. In this light environment, there is no Lustre cluster, no Window Viz nodes. `Az-hop` CentOS 7.9 Azure marketplace images for compute and remote desktop nodes will be used.

When provisioning a complete `az-hop` environment a deployer VM and a bastion will be included. Once deployed, a cloud init script is run from the deployer VM to install and configure all components needed using Ansible playbooks. This second step is longer as it needs to install and configure Domain Control, CycleCloud, OpenOndemand, PBS, Grafana and many other things. The use of Ansible will allow this system to be updated and in case of failure the installation to be repaired.

## Requirements

- AzHop Lab.
> Note: If you don't have the AzHop environment installed in your lab. Follow the [Quick install](https://azure.github.io/az-hop/tutorials/quick_install.html) guide.

## Exercise 1: Review the main az-hop features

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

   > Note: Be careful when pasting the commands to make sure the exacts characters are used, especially for hyphen.

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

### Task 3: Hello World job

1. On the lab computer, in the browser window displaying the Azure HPC On-Demand Platform portal, navigate to the **Dashboard** page.
On the **Dashboard** page, select the **Jobs** menu title, and from the drop-down menu, select **Job Composer**.
1. On the **Jobs** page, select **+ New job**, and from the drop-down menu, select **From Default Template**.

   > Note: This will automatically create a job named **(default) Sample Sequential Job** that targets the **execute** CycleCloud array. To identify the content of the job script, ensure that the newly created job is selected, and then review the **Script contents** pane.

1. Repeat the previous step twice to create two additional jobs based on the default template.

   > Note: The default job template contains a trivial script that runs `echo "Hello World"`.

1. Note that all three jobs are currently in the **Not Submitted** state. To submit them, select each one of them, and then select **Submit**.

   > Note: The status of the jobs should change to **Queued**.

1. On the lab computer, in the browser window displaying the Azure HPC On-Demand Platform portal, select the **Azure HPC On-Demand Platform** header. Select the **Monitoring** menu, and from the drop-down list, select **Azure CycleCloud**.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, monitor the status of the cluster and note that the number of nodes increased to **2**, which initially are listed in the **acquiring** state. This can takes a minute to come.
1. On the **Nodes** tab, verify that **execute** appears in the **Template** column, the **Nodes** column contains the entry **2**, and the **Last status** column displays the **Creating VM** message.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, on the **pbs1** page, select the **Scalesets** tab. Note a scaleset that hosts the cluster nodes with its size set to **2**.
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

1. Navigate back to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the node status until it changes to terminating, which will result eventually in their deletion. This should be done after about 15 minutes of idle time.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, on the **pbs1** page, select the **Scalesets** tab.
1. Note that the scaleset hosting the cluster nodes persists but its size is set to **0**.

### Task 4: Running Intel MPI PingPong jobs from the Job composer

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

1. To review the job output, switch to the **Azure HPC On-Demand Platform** portal, select the **Jobs** menu, and then from the drop-down menu, select **Job Composer**.
1. On the **Jobs** page, select any of the **Intel MPI PingPong** job entries, and in the **Folder Contents** section, select **PingPong.o??**.

1. Navigate to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the node status until it changes to terminating, resulting eventually in their deletion.
1. In the **Azure CycleCloud for Azure HPC On-Demand Platform** portal, on the **pbs1** page, select the **Scalesets** tab.
1. Note that the scaleset hosting the cluster nodes persists but its size is set to **0**.

   > Note: This will automatically open another web browser tab displaying the output of the job.

### Task 5: Running interactive apps using Code Server and Linux Desktop

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
1. You can now edit any files located in your home directory, git clone repos and connect to your GitHub account.
1. Switch back to the **Azure HPC On-Demand Platform** home page, or the `Dashboard`.
1. Select **Linux Desktop**.
1. On the **Linux Desktop** launching page, from the **Session target** drop-down list, ensure that **With GPU - Small GPU node for single session** is selected.
1. In the **Maximum duration of your remote session** field, enter **1**
1. Select **Launch**.

   > Note: This will begin compute node provisioning of the type you specified. This also creates a new job with its **Queued** status displaying on the same page.

1. Switch back to the **Linux Desktop** launching page.
1. From the **Session target** drop-down list, select **Without GPU - for single session**.
1. In the **Maximum duration of your remote session** field, enter **1**
1. Select **Launch**.

   > Note: The ability to extend the time you specify is not supported. After the time you specified passes, the session terminates. However, you can choose to terminate the session early.

   > Note: This will initiate the provisioning of a compute node of the type you specified. Note that this creates a new job and the **Queued** status for this job is displayed on the same page.

1. Switch to the **Azure CycleCloud for Azure HPC On-Demand Platform** portal and monitor the progress of the **viz** and **viz3d** node provisioning.

   > Note: Wait until the status of the node changes to **Ready**. This should take about 10 minutes.

   > Note: The **viz3d** node provisioning will fail if your subscription doesn't offer **Standard_NV6** SKU in the Azure region hosting your az-hop deployment.

1. Switch back to the **My Interactive Sessions** page, and then verify that the corresponding job's status has changed to **Running**.
1. Use the **Delete** button to delete one of the **Linux Desktop** session by selecting **Confirm** when prompted.
1. On the session with hosts named `viz3d-1`, adjust **Compression** and **Image quality** according to your preferences, and then select **Launch Linux Desktop**.

   > Note: This will open another browser tab displaying the Linux Desktop VNC session.

1. Open a terminal and run `nvidia-smi` to validate that GPU is enabled
1. In the open terminal run `/opt/VirtualGL/bin/glxspheres64` and observed the performances. This is running witout GPU acceleration and should deliver about **40 frames/sec**.
1. Close the **GLX Spheres** window and rerun it by prefixing the command with vglrun to offload Opengl to the GPU: `vglrun /opt/VirtualGL/bin/glxspheres64`. Performances should be increased to about **400 frames/sec** depending on your screen size, quality and compression options.
1. Start a new terminal and launch `nvidia-smi` to check the GPU usage which should be about **35%**.

> Note: The `vglrun` command can be called for all applications which use Opengl to offload calls to the GPU.

1. Switch back to the **My Interactive Sessions** launching page and use the **Delete** button to delete the **Linux Desktop** jobs by selecting **Confirm** when prompted.

1. Delete any remaining sessions.
## Exercise 2: Set up Spack

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

1. In the **Terminal** pane, review and then run the following scripts to install and configure `Spack`:

   ```bash
   ~/azurehpc/experimental/azhop/spack/install.sh
   ~/azurehpc/experimental/azhop/spack/configure.sh
   ```

   > Note: The output should resemble the following listing:

   ```bash
   [clusteradmin@hb120v2-1 ~]$ ~/azurehpc/experimental/azhop/spack/install.sh
   Cloning into '/anfhome/clusteradmin/spack'...
   remote: Enumerating objects: 402411, done.
   remote: Counting objects: 100% (163/163), done.
   remote: Compressing objects: 100% (122/122), done.
   remote: Total 402411 (delta 70), reused 83 (delta 19), pack-reused 402248
   Receiving objects: 100% (402411/402411), 200.65 MiB | 45.82 MiB/s, done.
   Resolving deltas: 100% (161555/161555), done.
   Note: checking out '13e6f87ef6527954b152eaea303841978e83b992'.

   You are in 'detached HEAD' state. You can look around, make experimental
   changes and commit them, and you can discard any commits you make in this
   state without impacting any branches by performing another checkout.

   If you want to create a new branch to retain commits you create, you may
   do so (now or later) by using -b with the checkout command again. Example:

   git checkout -b new_branch_name

   Checking out files: 100% (9474/9474), done.

   [clusteradmin@hb120v2-1 ~]$ ~/azurehpc/experimental/azhop/spack/configure.sh
   Configuring for OpenMPI Version 4.1.1
   Configuring for HPCX Version 2.9.0
   Configuring for GCC version 9.2.0
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

## Exercise 3: Build and run OSU Benchmarks
In this exercise, you will build and run some of the OSU Benchmarks used to measure latency and bandwidth using OpenMPI.

Duration: 30 minutes
### Task 1: Build OSU Benchmarks with OpenMPI
1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following command to load Spack modules:

   ```bash
   . ~/spack/share/spack/setup-env.sh
   module use /usr/share/Modules/modulefiles
   ```
1. List modules available. These contains the all the modules provided in the Azure HPC marketplace image, like Intel MPI, OpenMPI, HPCX and MVAPICH2.

   ```bash
   [clusteradmin@hb120v2-1 ~]$ module avail

   --------------------------------------------------------------------------------------------- /usr/share/Modules/modulefiles ---------------------------------------------------------------------------------------------
      amd/aocl              dot          module-git     modules            mpi/hpcx               mpi/impi_2021.4.0    mpi/impi-2021    mpi/mvapich2-2.3.6    mpi/openmpi-4.1.1 (D)    use.own
      amd/aocl-2.2-4 (D)    gcc-9.2.0    module-info    mpi/hpcx-v2.9.0    mpi/impi_2018.4.274    mpi/impi             mpi/mvapich2     mpi/openmpi           null

   ----------------------------------------------------------------------------------------- /usr/share/lmod/lmod/modulefiles/Core ------------------------------------------------------------------------------------------
   ```

1. Install OSU benchmarks with Spack and OpenMPI
   ```bash
   spack install osu-micro-benchmarks^openmpi
   ```
This will download the source packages and build them in your environment.

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
1. Submit a first job for running the bandwidth benchmarks. Note the **slot_type** used in the select statement to specify on which CycleCloud node array to submit to.
```bash
qsub -N BW -joe -koe -l select=2:slot_type=hb120v2 -- osu_benchmarks.sh osu_bw
```

1. And a second one for the latency test
```bash
qsub -N LAT -joe -koe -l select=2:slot_type=hb120v2 -- osu_benchmarks.sh osu_latency
```

1. Check the jobs statuses within the terminal or thru the web UI as well as the node provisioning state in the CycleCloud portal.

1. Review the results of the jobs in files names **LAT.o??** and **BW.o??** at the root of the home directory


## Exercise 4: Build, run, and analyze OpenFOAM

In this exercise, you will build, run, and analyze CFD simulation using OpenFOAM.

Duration: 60 minutes

### Task 1: Build OpenFOAM

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following command to build OpenFOAM 8:

   ```bash
   . ~/spack/share/spack/setup-env.sh
   module use /usr/share/Modules/modulefiles
   spack install openfoam-org@8
   ```
   > Note: Wait for the build to complete. This might take about 50 minutes.
### Task 2: Running the motorbike tutorial on a single node

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following command to load OpenFOAM modules:
   ```bash
   spack load openfoam-org@8
   ```

1. Copy the motorbike tutorial into your home directory

   ```bash
   cd
   cp -r $WM_PROJECT_DIR/tutorials/incompressible/simpleFoam/motorBike .
   ```

1. Run the case
   ```bash
   cd motorBike
   ./Allrun
   ```
This is taking few minutes.

1. Review all log files `log.*` for any errors

### Task 3: Running the motorbike tutorial on multiple nodes

The following updates are needed:

- Add FOAM_MPIRUN_FLAGS to the mpirun command when using runParallel (needed for all version of OpenFOAM)
- Reconstruct the single partition after the solve

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following commands:

   ```bash
      cd ~/motorBike
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

3. Save that file under `~/motorBike/submit.sh`

1. Run the OpenFOAM job
Here we ask for 2 node from the node array **hb120v2** using 120 cores on each, and asking to be exclusive on these 2 nodes.

   ```bash
   cd ~/motorBike
   rm log.*
   qsub -l select=2:slot_type=hb120v2:ncpus=120:mpiprocs=120,place=scatter:excl submit.sh
   ```

1. Monitor the job and wait for the job to be finished

### Task 4: Visualize the motorbike tutorial result

1. On the lab computer, in the browser window, switch back to the **Azure HPC On-Demand Platform** portal, and then in the **Interactive Apps** section, select **Linux Desktop**.
1. On the **Linux Desktop** launching page, from the **Session target** drop-down list, ensure that **With GPU** entry is selected. In the **Maximum duration of your remote session** field, enter **1**,  and then select **Launch**.

   > Note: This will begin compute node provisioning of the type you specified. This also creates a new job with its **Queued** status displaying on the same page.

1. Switch back to the **Linux Desktop** launching page, and then verify that the corresponding job's status has changed to **Running**.
1. Adjust **Compression** and **Image quality** according to your preferences, and then select **Launch Linux Desktop**.

   > Note: This will open another browser tab displaying the Linux Desktop session.

1. Within the Linux Desktop session, start **Terminal Emulator**.

1. Install the **ParaView** viewer

```bash
wget "https://www.paraview.org/paraview-downloads/download.php?submit=Download&version=v5.10&type=binary&os=Linux&downloadFile=ParaView-5.10.1-MPI-Linux-Python3.9-x86_64.tar.gz" -O ParaView-5.10.1-MPI-Linux-Python3.9-x86_64.tar.gz
tar xvf ParaView-5.10.1-MPI-Linux-Python3.9-x86_64.tar.gz
```

7. Create a case file and launch ParaView

```bash
touch ~/motorBike/case.foam
vglrun ./ParaView-5.10.1-MPI-Linux-Python3.9-x86_64/bin/paraview
```

8. Open the model

Within **ParaView** open the case `~/motorBike/case.foam`

When the model is loaded, you can view the geometry like this:
- In the bottom left pane, in the "Mesh Regions" list, unselect "internalMesh" and select "group/motorBikeGroup".
- Click "Apply" above the list.
- You should now see the model geometry, and you can move/rotate/zoom using the mouse.

Next, you can visualize the simulation results.
- Click the "Play" button on the toolbar at the top of the window to advance to the end of the simulation.
- On the Active Variables Control toolbar you will find a drop down box where you can select variables. For example, select "p" for pressure.

## Exercise 5: Run OpenFOAM DrivAer-Fastback simulation using EESSI stack

The Az-HOP deployment in this tutorial comes with the [EESSI software stack](https://eessi.github.io/docs) pre-configured on all compute nodes.
In this exercise you will run and analyze the DrivAer-Fastback CFD simulation with 3 million cells without having to build OpenFOAM by using `OpenFOAM/9-foss-2021a` available in EESSI.

### Task 1: Prepare the DrivAer-Fastback example

1. On the lab computer, in the browser window displaying the Code Server, in the **Terminal** pane, at the **[clusteradmin@hb120v2-1 ~]$**  prompt, run the following command to Clone the OpenFOAM-9 repository from GitHub:

   ```bash
   git clone https://github.com/OpenFOAM/OpenFOAM-9.git
   ```

1. Copy the DrivAer-Fastback tutorial to your home directory:

   ```bash
   cp -r OpenFOAM-9/tutorials/incompressible/simpleFoam/drivaerFastback ~
   ```

1. Apply the following changes to the default tutorial:
- Add `FOAM_MPIRUN_FLAGS` to the `mpirun` command when using `runParallel` (needed for all version of OpenFOAM)
- Decompress the geometry
- Rename `constant/geometry` to 'constant/triSurface`
- Reconstruct the single partition after the solve

Here are the commands:

   ```bash
   cd ~/drivaerFastback
   sed -i '/RunFunctions/a source <(declare -f runParallel | sed "s/mpirun/mpirun \\\$FOAM_MPIRUN_FLAGS/g")' Allrun
   sed -i 's#/bin/sh#/bin/bash#g' Allrun
   gunzip constant/geometry/*
   mv constant/geometry constant/triSurface
   sed -i 's/# runApplication reconstructPar/runApplication reconstructPar/g' Allrun
   ```

### Task 2: Submit PBS job

1. Create a PBS submit script as `~/drivaerFastback/submit.sh`. When running on multiple nodes it is necessary to export all the OpenFOAM environment variables (unless you add loading the modules in `.bashrc`). This is done with the `FOAM_MPIRUN_FLAGS` that we added to the `runParallel` in the previous step. The script will run for the number of cores specified to PBS (`select` x `mpiprocs`):

   ```bash
   #!/bin/bash

   source /cvmfs/pilot.eessi-hpc.org/versions/2021.12/init/bash
   ml OpenFOAM/9-foss-2021a
   source $FOAM_BASH
   $PBS_O_WORKDIR/Allclean

   ranks_per_numa=30
   export FOAM_MPIRUN_FLAGS="-mca pml ucx -hostfile $PBS_NODEFILE $(env |grep 'WM_\|FOAM_' | cut -d'=' -f1 | sed 's/^/-x /g' | tr '\n' ' ') -x MPI_BUFFER_SIZE -x UCX_POSIX_USE_PROC_LINK=n -x PATH --map-by ppr:${ranks_per_numa}:numa"
   $PBS_O_WORKDIR/Allrun -m M -cores $(wc -l <$PBS_NODEFILE)
   ```

2. Submit the OpenFOAM batch job, requesting our job to be exclusively allocated to two HB120rs_v2 nodes from the node array `hb120v2`:

   ```bash
   cd ~/drivaerFastback
   qsub -l select=2:slot_type=hb120v2:ncpus=120:mpiprocs=120,place=scatter:excl submit.sh
   ```

3. Monitor the node allocation in CycleCloud and the job until its completion by using the `qstat` command. Log files will be generated in the `~/drivaerFastback` with the pattern `log.*`. Expect the job to run for about 12 minutes.

### Task 3: Create Linux Desktop session for visualization

1. On the lab computer, in the browser window, switch back to the **Azure HPC On-Demand Platform** portal, and then in the **Interactive Apps** section, select **Linux Desktop**.

2. On the **Linux Desktop** launching page, from the **Session target** drop-down list, ensure that **With GPU** entry is selected. In the **Maximum duration of your remote session** field, enter **1**,  and then select **Launch**.

   > Note: This will begin compute node provisioning of the type you specified. This also creates a new job with its **Queued** status displaying on the same page.

3. Switch back to the **Linux Desktop** launching page, and then verify that the corresponding job's status has changed to **Running**.
4. Adjust **Compression** and **Image quality** according to your preferences, and then select **Launch Linux Desktop**.

   > Note: This will open another browser tab displaying the Linux Desktop session.

5. Within the Linux Desktop session, start **Terminal Emulator**.

6. Install the **ParaView** viewer:

   ```bash
   wget "https://www.paraview.org/paraview-downloads/download.php?submit=Download&version=v5.10&type=binary&os=Linux&downloadFile=ParaView-5.10.1-MPI-Linux-Python3.9-x86_64.tar.gz" -O ParaView-5.10.1-MPI-Linux-Python3.9-x86_64.tar.gz
   tar xvf ParaView-5.10.1-MPI-Linux-Python3.9-x86_64.tar.gz
   ```

### Task 4: Visualize the DrivAer-Fastback simulation results

1. Create a case file and launch ParaView:

   ```bash
   touch ~/drivaerFastback/case.foam
   vglrun ./ParaView-5.10.1-MPI-Linux-Python3.9-x86_64/bin/paraview
   ```

1. Within **ParaView** open the case `~/drivaerFastback/case.foam`

1. When the model is loaded, you can load the car geometry as follows:
   - In the bottom left pane, in the "Mesh Regions" list, unselect "internalMesh" and select the    following fields:
      - `patch/body`
      - `patch/frontWheels`
      - `patch/ground`
      - `patch/inlet`
      - `patch/rearWheels`
   - Click "Apply" above the list
   - You should now see the model geometry, and you can move/rotate/zoom using the mouse

1. To visualize the simulation results, click the "Play" button on the toolbar at the top of the window to advance to the end of the simulation.

1. On the Active Variables Control toolbar you will find a drop down box where you can select variables. For example, select "p" for pressure.

## Exercise 6: Deprovision Azure HPC OnDemand Platform environment

Duration: 5 minutes

In this exercise, you will deprovision the Azure HPC OnDemand Platform lab environment.

### Task 1: Deprovision the Azure resources

1. On the lab computer, switch to the browser window displaying the Azure portal
1. Delete the resource group you have chosen to deploy azhop in.


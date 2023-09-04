<!--ts-->
* [Application Integration](#application-integration)
* [Application Catalog](#application-catalog)
   * [ANSYS Workbench](#ansys-workbench)
      * [Prerequisites](#prerequisites)
      * [Versions](#versions)
      * [Enabling the OnDemand application](#enabling-the-ondemand-application)
      * [Update a running environment](#update-a-running-environment)
      * [License](#license)
   * [Visual Molecular Dynamics](#visual-molecular-dynamics)
      * [Prerequisites](#prerequisites-1)
      * [Enabling the OnDemand application](#enabling-the-ondemand-application-1)
      * [Update a running environment](#update-a-running-environment-1)
      * [License](#license-1)
<!--te-->
# Application Integration

There are several scenarios for application integration depending on the type of application being used. These can be split in two main categories, but they are sharing the same concept being run as a job :
- Interactive Applications (Rich UI or Web based)
- CLI only applications

For CLI only applications those are mostly recipes on how to package, share and integrate them with the job schedulers supported by az-hop (OpenPBS and SLURM). Tuning guidance can be embedded in these recipes based on the VM types like pinning, placement, etc... For some applications a license server is required which means dedicated ports would have to be open to reach these if outside of the azhop vnet. Today there are no direct configuration settings in azhop and ports need to be specifically open in your networking.

For interactive applications, Open OnDemand provides a mechanism to add application launchers as documented [here](https://osc.github.io/ood-documentation/latest/app-development/interactive.html), with many samples already published [here](https://openondemand.org/run-open-ondemand#enabled-applications). The main drawback is that these applications are hosted in separate repositories and most of the time not generic enough to be reused as is. While it’s totally possible to manually add external applications as described in the Open OnDemand documentation these are not integrated with the deployment and version management of azhop. So to better handle application integration, control and versioning there are specific locations in which you can contribute to easily add an application. Each application integration artifacts lives in its own directory under `playbooks/roles/ood-applications/files` and deployed thru the *ood-applications* ansible role. Enabling/Disabling applications can be done in the config.yml file as described below, and deployed/updated by running this command `./install.sh ood-custom`

```yml
# Application settings
applications:
  bc_codeserver:
    enabled: true
  bc_jupyter:
    enabled: true
  bc_ansys_workbench:
    enabled: false
  bc_vmd:
    enabled: false
```

There are actually 9 application folder under the ood-applications ansible role :
- [bc_ansys_workbench](#ansys-workbench) : Ansys Workbench launcher running as a Linux Remote Desktop session
- bc_codeserver : VS Code running on a compute node and exposed thru a web page
- bc_jupyter : A jupyter notebook started in a container and exposer thru a web page
- [bc_vmd](#visual-molecular-dynamics) : A Visual Molecular Dynamics launcher running as a Linux Remote Desktop session
- cyclecloud : A python passenger application to launch the Cycle Cloud Web UI
- grafana : A python passenger application to launch the Grafana Web UI
- robinhood : A python passenger application to launch the Robinhood Web UI

The specific bc_* pattern comes from Open OnDemand and means that the Batch Connect feature is used. This provides form design, job scheduler integration, remote desktop integration, session management and more.
To add a new Interactive Application named `foo` follow these steps :
- Read this Open OnDemand [documentation](https://osc.github.io/ood-documentation/latest/app-development/interactive.html),
- Duplicate one of the `bc_*` existing folder in *playbooks/roles/ood-applications/files/bc_foo*
- Update *bc_foo/manifest.yml*
- Update ruby and script files under *bc_foo* specifically to your application requirements
- Update *bc_foo/readme.md* for any installation instructions to follow if the application is not installed at runtime
- In the *playbooks/roles/ood-applications/defaults/main.yml* file, add a line for *bc_foo* in the `ood_azhop_apps` list, make enabled default to false
- Update the template configuration *config.tpl.yml* file with the application settings for *bc_foo* 
- Enabled *bc_foo* in your current *config.yml* file
- Deploy the applications by run the ood-custom ansible playbook : `./install.sh ood-custom`
- Browse to the azhop home page, login and restart your web server session by selecting the *Restart Web Server* choice in the *Help* menu.
- Test your application
- Your *bc_foo* application files will be copied on the ondemand vm under */var/www/ood/apps/sys/bc_foo/*. You can also connect to the ondemand VM and locally update these files directly to reduce the test cycle. To be applied you need to restart the web server. Don’t forget to synchronize your code back to your development VM when done.

# Application Catalog
## ANSYS Workbench
An Open OnDemand Batch Connect application designed for `az-hop` that launches an ANSYS Workbench session within a batch job.

Adapted from https://github.com/OSC/bc_osc_ansys_workbench

### Prerequisites
[ANSYS Workbench] need to be installed on a file share system accessible by the nodes. 
The default ANSYS root directory is defined as `/anfhome/apps/ansys`, but it can be changed in the `form.yml.erb` file and is a parameter in the UI.

### Versions
The default version is `2021R2` and is mapped to the `/anfhome/apps/ansys/v212` folder to launch ANSYS Workbench. If you need to add another version then :
- Add a new option in the select version widget in the `form.yml.erb` file.
- make sure that the value used for the option match the folder in which the version will be installed. The path will be the concatenation of the ANSYS root directory and the version value.

### Enabling the OnDemand application
By default, [ANSYS Workbench] is disabled. To enable it, update the `enabled` property to `true` for the `bc_ansys_workbench` application in `applications` section of your config file.

```yml
# Application settings
applications:
  - bc_ansys_workbench:
    enabled: true
```

### Update a running environment
To update an existing environment you have to applu the `ood-custom` playbook by running this command :
```bash
$ ./install.sh ood-custom
```

[ANSYS Workbench]: https://www.ansys.com/

### License

* Ansys, Ansys Workbench, Ansoft, AUTODYN, CFX, FLUENT, HFSS and any and all ANSYS, Inc. brand, product, service and feature names, logos and slogans are trademarks or registered trademarks of ANSYS, Inc. or its subsidiaries located in the United States or other countries.

## Visual Molecular Dynamics
An Open OnDemand app designed for `az-hop` that launches VMD session within a batch job.

Adapted from https://github.com/OSC/bc_osc_vmd

### Prerequisites

[VMD] need to be installed on a file share system accessible by the nodes. 
The default VMD root directory is defined as `/anfhome/apps/vmd`, but it can be changed in the `form.yml.erb` file and is a parameter in the UI.

### Enabling the OnDemand application
By default, [VMD] is disabled. To enable it, update the `enabled` property to `true` for the `bc_vmd` application in `applications` section of your config file.

```yml
# Application settings
applications:
  - bc_vmd:
    enabled: true
```

### Update a running environment
To update an existing environment you have to applu the `ood-custom` playbook by running this command :
```bash
$ ./install.sh ood-custom
```

[VMD]: http://www.ks.uiuc.edu/Research/vmd/

### License

* VMD and its logo are intellectual property owned by the University of Illinois, and all right, 
title and interest, including copyright, remain with the University.
# Batch Connect - Ondemand - ANSYS Workbench
An Open OnDemand Batch Connect application designed for `az-hop` that launches an ANSYS Workbench session within a batch job.

Adapted from https://github.com/OSC/bc_osc_ansys_workbench

## Prerequisites
[ANSYS Workbench] need to be installed on a file share system accessible by the nodes. 
The default ANSYS root directory is defined as `/anfhome/apps/ansys`, but it can be changed in the `form.yml.erb` file and is a parameter in the UI.

## Versions
The default version is `2021R2` and is mapped to the `/anfhome/apps/ansys/v212` folder to launch ANSYS Workbench. If you need to add another version then :
- Add a new option in the select version widget in the `form.yml.erb` file.
- make sure that the value used for the option match the folder in which the version will be installed. The path will be the concatenation of the ANSYS root directory and the version value.

## Enabling the OnDemand application
By default, [ANSYS Workbench] is disabled. To enable it, update the `enabled` property to `true` for the `bc_ansys_workbench` application in `applications` section of your config file.

```yml
# Application settings
applications:
  - bc_ansys_workbench:
    enabled: true
```

## Update a running environment
To update an existing environment you have to applu the `ood-custom` playbook by running this command :
```bash
$ ./install.sh ood-custom
```

[ANSYS Workbench]: https://www.ansys.com/

## License

* Ansys, Ansys Workbench, Ansoft, AUTODYN, CFX, FLUENT, HFSS and any and all ANSYS, Inc. brand, product, service and feature names, logos and slogans are trademarks or registered trademarks of ANSYS, Inc. or its subsidiaries located in the United States or other countries.
# Batch Connect - Ondemand - VMD
An Open OnDemand app designed for `az-hop` that launches VMD session within a batch job.

Adapted from https://github.com/OSC/bc_osc_vmd

## Prerequisites

[VMD] need to be installed on a file share system accessible by the nodes. 
The default VMD root directory is defined as `/anfhome/apps/vmd`, but it can be changed in the `form.yml.erb` file and is a parameter in the UI.

## Enabling the OnDemand application
By default, [VMD] is disabled. To enable it, update the `enabled` property to `true` for the `bc_vmd` application in `applications` section of your config file.

```yml
# Application settings
applications:
  - bc_vmd:
    enabled: true
```

## Update a running environment
To update an existing environment you have to applu the `ood-custom` playbook by running this command :
```bash
$ ./install.sh ood-custom
```

[VMD]: http://www.ks.uiuc.edu/Research/vmd/

## License

* VMD and its logo are intellectual property owned by the University of Illinois, and all right, 
title and interest, including copyright, remain with the University.
# Batch Connect - Ondemand - vizer

An Open OnDemand app designed for `az-hop` that launches a [vizer] session within a batch job.
This app can be used a template for any [trame] or similar application for web visualization.

## Enabling the OnDemand application

By default, [vizer] is disabled. To enable it, update the `enabled` property to `true` for the `bc_vizer`
application in `applications` section of your config file.

```yml
# Application settings
applications:
  - bc_vizer:
    enabled: true
```

## Update a running environment

To update an existing environment you have to apply the `ood-custom` playbook by running this command :

```bash
$ ./install.sh ood-custom
```

[vizer] is distributed under the OSI-approved MIT License.

[vizer]: https://github.com/utkarshayachit/vizer
[trame]: https://kitware.github.io/trame/index.html

# Batch Connect - Example RStudio Server

![GitHub Release](https://img.shields.io/github/release/osc/bc_example_rstudio.svg)
![GitHub License](https://img.shields.io/github/license/osc/bc_example_rstudio.svg)

An example Batch Connect app that launches an RStudio server within a
batch job.

## Prerequisites

This Batch Connect app requires the following software be installed on the
**compute nodes** that the batch job is intended to run on (**NOT** the
OnDemand node):

- [RStudio](https://www.rstudio.com/)
- [R](https://www.r-project.org/)
- [Singularity](https://www.sylabs.io/docs/)

All Batch Connect apps also require the following on the compute nodes:

- [Websockify](https://pypi.org/project/websockify/)
- [TurboVNC](https://turbovnc.org)
- [nc (netcat)](http://netcat.sourceforge.net/)

**Optional** software:

- [Lmod](https://www.tacc.utexas.edu/research-development/tacc-projects/lmod)
  6.0.1+ or any other `module purge` and `module load <modules>` based CLI
  used to load appropriate environments within the batch job before launching
  the RStudio server.

## Install

If you have not already be sure to start with the section about setting up your system for [Batch Connect development](https://osc.github.io/ood-documentation/master/app-development/interactive/setup.html). Detailed installation instructions for this app are included in the [OnDemand documentation](https://osc.github.io/ood-documentation/master/app-development/tutorials-interactive-apps/add-rstudio.html).

Note that this example assumes that the compute host is CentOS 7. In order to ensure correct behavior it is important that the guest is built from the same OS as the host (type and major version), this is because most of the host's system directories are bind-mounted into the guest.

## Contributing

1. Fork it ( https://github.com/OSC/bc_example_rstudio/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

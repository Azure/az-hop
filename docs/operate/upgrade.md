# Upgrade az-hop

When new versions of az-hop are released, you can upgrade your deployment by pulling in changes via `git`. Please follow these steps:

 * Read [release notes](https://github.com/Azure/az-hop/releases) of all versions between your current version and the version you are upgrading to.
   In particular, check for breaking changes in the `config.yml`.
 * If the upgrade involves changes at the Azure infrastructure level, rerun the terraform step via `./build.sh -a apply`
 * remove `./playbooks/*.ok` and run `./install.sh`